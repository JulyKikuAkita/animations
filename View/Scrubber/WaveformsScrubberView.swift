//
//  WaveformsScrubberView.swift
//  animation
// Do not create multiple rectangles in a hstack for wave forms
// Use custom shapes
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
