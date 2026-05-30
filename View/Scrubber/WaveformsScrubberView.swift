//
//  WaveformsScrubberView.swift
//  animation
//
//  Standalone demo (not wired into the app's demo browser; preview-only).
//  iOS 17+ — uses `onGeometryChange`, `Task.detached(priority:)`.
//
//  ⚠️  PERFORMANCE TIP (was the original top comment, kept here):
//      Don't draw waveforms by rendering N rectangles in an HStack.
//      Use a CUSTOM `Shape` (`WaveFormShape` below) and add a
//      single path. SwiftUI's diff cost on hundreds of children
//      kills frame rate during scrubbing.
//
//  TODO: Cleanup candidates
//        1. Function name typo: `downszieAudioSamples` (line ~170)
//           should be `downsizeAudioSamples`. Internal-only — safe
//           project-wide rename.
//        2. **Real bug**: `convertMP4ToAudio` (line ~190) writes
//           the converted `.m4a` to the source URL's directory:
//             `outputURL = url.deletingPathExtension().appendingPathExtension("m4a")`
//           For `Bundle.main.url(forResource:)` URLs, that's the
//           app bundle — read-only at runtime. The export will
//           fail silently (only `print`ed). Write to
//           `FileManager.default.temporaryDirectory` instead, or
//           cache by hash in `.cachesDirectory`.
//        3. `Task.detached(priority: .high) { ... }` for sample
//           extraction is fine, but `extractAudioSamples`'s
//           `try file.read(into: buffer)` allocates a buffer sized
//           by `frameCount` (full file length). For a 5-min wav
//           that's tens of millions of floats; consider streaming
//           in chunks if real audio gets larger than demo files.
//
//  Learning point
//  ──────────────
//  Custom audio waveform scrubber: reads an audio file via
//  `AVAudioFile`, downsamples to one peak-amplitude per pixel
//  column, and draws via a single `Shape` path. A drag gesture
//  scrubs the playhead and writes back through the `progress`
//  Binding so callers can sync to actual audio playback.
//
//  Three layers:
//    1. **Sample extraction** (`Task.detached`, off-main):
//       AVAudioFile → AVAudioPCMBuffer → `[Float]` of raw samples.
//       For .mp4 video, the file is first exported to .m4a via
//       `AVAssetExportSession` (see TODO #2 about the buggy output
//       path).
//    2. **Downsampling**: collapse N raw samples into M peaks where
//       M ≈ viewWidth / (spacing + shapeWidth). Each output peak
//       is `chunk.max()` — the highest absolute amplitude in that
//       slice. This is what makes the waveform look right at any
//       view width.
//    3. **Rendering**: ZStack of two `WaveFormShape` instances
//       sharing the same downsampled array. Inactive layer fills
//       in gray; active layer fills in the tint color, then is
//       MASKED to `Rectangle().scale(x: progress, anchor: .leading)`.
//       Result: the bar fills from left as `progress` advances.
//
//  Gesture mechanics:
//    • `@GestureState isActive` flips true during a drag and is
//      published outward via `onGestureActive` — callers can pause
//      audio playback while the user is scrubbing.
//    • `lastProgress` snapshots the current progress at drag start;
//      delta = `value.translation.width / viewSize.width`. So a
//      drag from anywhere on the bar adjusts FROM that anchor,
//      rather than jumping to the touched x-position.
//    • The `onChange(of: progress)` updates `lastProgress` only
//      when the change came from OUTSIDE (i.e. `!isActive`), so
//      audio-playback-driven progress doesn't fight the gesture.
//
//  Key APIs
//  ────────
//  • `AVAudioFile` + `AVAudioPCMBuffer` + `floatChannelData` — the
//    PCM-sample read path. Always pass `format: file.processingFormat`
//    so the buffer matches the file's native format.
//  • `AVAssetExportSession(asset:presetName: AVAssetExportPresetAppleM4A)`
//    + `.export(to:as:)` — async-throwing export for the MP4→M4A
//    fallback path.
//  • Custom `Shape` (`WaveFormShape`) — defined elsewhere; the
//    performance-critical primitive. ONE path, drawn once per
//    state change.
//  • `Rectangle().scale(x: progress, anchor: .leading)` as a `mask`
//    — neat way to "fill from left" without computing per-bar
//    boolean state.
//  • `nonisolated func ... async` — used for the off-actor extraction
//    helpers so `Task.detached` doesn't trip MainActor isolation.
//
//  How to apply
//  ────────────
//  Use as a starting point for any media scrubber that needs
//  amplitude visualisation — voice memos, podcasts, music players.
//  Fix the m4a-output-path bug (TODO #2) before shipping. For
//  pure-audio progress without amplitude (just a track + thumb),
//  you don't need any of this — `Slider` is enough.
//
//  See also
//  ────────
//  • View/Slider/* — non-amplitude scrubbers.
//  • View/Video/* — likely consumers if any of those demos add
//    audio scrubbing.
//
import AVKit
import SwiftUI

struct WaveformsScrubberDemoView: View {
    @State private var wavProgress: CGFloat = 0
    @State private var mp4progress: CGFloat = 0
    var body: some View {
        NavigationStack {
            List {
                if let audioURL {
                    Section("Audio wave") {
                        WaveformsScrubberView(url: audioURL, progress: $wavProgress) { info in
                            print(info.duration)
                        } onGestureActive: { _ in
                        }
                        .frame(height: 60)
                    }
                    Slider(value: $wavProgress)
                }
                if let reelURL {
                    Section("Video wave") {
                        WaveformsScrubberView(url: reelURL, progress: $mp4progress) { info in
                            print(info.duration)
                        } onGestureActive: { _ in
                        }
                        .frame(height: 40)
                        .scaleEffect(y: 4)
                    }
                }
            }
        }
        .navigationTitle(Text("Waveforms Scrubber"))
    }

    /// AVAudioFile supports .wav, .aiff, .caf, m4a formats
    var audioURL: URL? {
        Bundle.main.url(forResource: "audio", withExtension: "wav")
    }

    var reelURL: URL? {
        Bundle.main.url(forResource: "Reel12", withExtension: "mp4")
    }
}

struct WaveformsScrubberView: View {
    var config: Config = .init()
    var url: URL
    /// Scrubber Progress
    @Binding var progress: CGFloat
    var info: (AudioInfo) -> Void = { _ in }
    var onGestureActive: (Bool) -> Void = { _ in }
    @State private var viewSize: CGSize = .zero
    /// View Properties
    @State private var samples: [Float] = []
    @State private var downsizedSamples: [Float] = []
    /// Gesture Properties
    @State private var lastProgress: CGFloat = 0
    @GestureState private var isActive: Bool = false
    var body: some View {
        ZStack {
            WaveFormShape(samples: downsizedSamples)
                .fill(config.inactiveTint)

            WaveFormShape(samples: downsizedSamples)
                .fill(config.activeTint)
                .mask {
                    Rectangle()
                        .scale(x: progress, anchor: .leading)
                }
        }
        .frame(maxWidth: .infinity)
        .contentShape(.rect)
        .gesture(
            DragGesture()
                .updating($isActive, body: { _, out, _ in
                    out = true
                }).onChanged { value in
                    let progress = max(min((value.translation.width / viewSize.width) + lastProgress, 1), 0)
                    self.progress = progress
                }.onEnded { _ in
                    lastProgress = progress
                }
        )
        // update progress from not gesture related update
        .onChange(of: progress) { _, newValue in
            guard !isActive else { return }
            lastProgress = newValue
        }
        .onChange(of: isActive) { _, newValue in
            onGestureActive(newValue)
        }
        .onGeometryChange(for: CGSize.self) {
            $0.size
        } action: { newValue in
            if viewSize == .zero {
                lastProgress = progress
            }
            viewSize = newValue
            initializeAudioFile(newValue)
        }
    }

    struct Config: Hashable {
        var spacing: Float = 2
        var shapeWidth: Float = 2
        var activeTint: Color = .black
        var inactiveTint: Color = .gray.opacity(0.7)
    }

    struct AudioInfo {
        var duration: TimeInterval = 0
    }
}

/// Use AVKit to exact audio wave form
extension WaveformsScrubberView {
    private func initializeAudioFile(_ size: CGSize) {
        guard samples.isEmpty else {
            return
        }
        Task.detached(priority: .high) {
            do {
                let audioURL = await isAVAudioFile(url) ? url : convertMP4ToAudio(url)
                let audioFile = try AVAudioFile(forReading: audioURL)
                let audioInfo = await extractAudioInfo(audioFile)
                let samples = try await extractAudioSamples(audioFile)

                let downSampleCount = Int(Float(size.width) / (config.spacing + config.shapeWidth))
                let downSamples = downszieAudioSamples(samples, downSampleCount)
                await MainActor.run { /// update UI
                    self.samples = samples
                    self.downsizedSamples = downSamples
                    self.info(audioInfo)
                }
            } catch {
                print("No audio info for \(url): \(error.localizedDescription)")
            }
        }
    }

    nonisolated func extractAudioSamples(_ file: AVAudioFile) async throws -> [Float] {
        let format = file.processingFormat
        let frameCount = UInt32(file.length)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return []
        }

        try file.read(into: buffer)
        if let channel = buffer.floatChannelData {
            let samples = Array(UnsafeBufferPointer(start: channel[0], count: Int(buffer.frameLength)))
            return samples
        }
        return []
    }

    nonisolated func extractAudioInfo(_ file: AVAudioFile) async -> AudioInfo {
        let format = file.processingFormat
        let sampleRate = format.sampleRate
        let duration = file.length / Int64(sampleRate)
        return .init(duration: TimeInterval(duration))
    }

    nonisolated func downszieAudioSamples(_ samples: [Float], _ count: Int) -> [Float] {
        let chunk = samples.count / count
        var downSampled: [Float] = []
        for index in 0 ..< count {
            let start = index * chunk
            let end = min((index + 1) * chunk, samples.count)
            let chunkSamples = samples[start ..< end]

            let maxValue = chunkSamples.max() ?? 0
            downSampled.append(maxValue)
        }
        return downSampled
    }

    func isAVAudioFile(_ url: URL) -> Bool {
        let validFormats = ["wav", "aiff", "caf", "m4a"]
        let fileExtension = url.pathExtension.lowercased()
        return validFormats.contains(fileExtension)
    }

    nonisolated func convertMP4ToAudio(_ url: URL) async -> URL {
        let fileExtension = url.pathExtension.lowercased()
        guard fileExtension == "mp4" else {
            return url
        }
        let asset = AVURLAsset(url: url)
        let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A)
        let outputURL = url
            .deletingPathExtension()
            .appendingPathExtension("m4a")
        do {
            try await exportSession?.export(to: outputURL, as: .m4a)
        } catch {
            print(error.localizedDescription)
            print("Unsupported file type: \(fileExtension)")
        }
        return outputURL
    }
}
