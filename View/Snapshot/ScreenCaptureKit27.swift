//
//  ScreenCaptureKit27.swift
//  animation
//
//  Created on 6/27/26.
//  Note: import ScreenCaptureKit only works on physical device + xcode 27 beta 2
import SwiftUI

// import ScreenCaptureKit
import CoreMedia

/// ScreenCaptureKit (iOS 27+)
///
/// To continue screen capture while the app is running in the background,
/// enable the **Screen Capture** background mode:
///
/// Signing & Capabilities
///   → Background Modes
///   → Check "Screen Capture"
///
/// Without this capability, screen capture will stop when the app moves to
/// the background.
///
/// Note:
/// The current app target does not expose the "Screen Capture" background
/// mode, so this capability cannot be enabled at this time.
struct ScreenCaptureKitDemo: View {
    @State private var recorder: ScreenRecorder = .init()
    var body: some View {
        NavigationStack {
            List {
                Section("Screen Stream") {
                    Rectangle()
                        .fill(.fill.tertiary)
                        .overlay {
                            if recorder.recordType == .stream {
                                if !recorder.isRecording {
                                    ContentUnavailableView(
                                        "No Stream",
                                        systemImage: "inset.filled.rectangle.and.person.slash"
                                    )
                                }
                            } else {
                                ContentUnavailableView(
                                    recorder.isRecording ? "Recording" : "No Stream",
                                    systemImage: recorder.isRecording ? "record.circle.fill" : "inset.filled.rectangle.and.person.slash"
                                )
                            }
                        }
                        .overlay {
                            if let cgImage = recorder.cgImageBuffer, recorder.isRecording {
                                Image(cgImage, scale: 1, label: Text(""))
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            }
                        }
                        .clipShape(.rect(cornerRadius: 20))
                        .aspectRatio(0.4615, contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: 400)
                }

                Section("Actions") {
                    Picker("", selection: $recorder.recordType) {
                        ForEach(RecordType.allCases, id: \.rawValue) { type in
                            Text(type.rawValue)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .controlSize(.large)
                }
                .disabled(recorder.isRecording)

                Button(recorder.isRecording ? "Stop Recording" : "Start Recording") {
                    if recorder.isRecording {
                        recorder.stopRecording()
                    } else {
                        recorder.startRecording()
                    }
                }
            }
            .listSectionSpacing(10)
            .navigationTitle(Text("Screen Capture Kit"))
        }
    }
}

enum RecordType: String, CaseIterable {
    case stream = "Stream Screen"
    case record = "Record & Save"
}

/// MARK: - ScreenCaptureKit Notes (iOS 27 / Xcode 27)
///
/// Current limitations and requirements:
///
/// 1. Xcode 27 Beta 2
///    ScreenCaptureKit is only available when building for a physical device.
///    Selecting an iOS Simulator as the active run destination will result in
///    build failures. This is expected to be a beta limitation.
///
/// 2. Info.plist
///    Apple's documentation requires the following privacy usage description:
///
///        NSScreenCaptureUsageDescription
///
///    As of Xcode 27 Beta 2, this key is not exposed in the Info editor and
///    ScreenCaptureKit functions without it. If a future SDK enforces this
///    requirement, be sure to add the key to your Info.plist.
///
/// 3. Background Recording
///    To allow screen recording to continue while the app is in the background,
///    enable the following capability:
///
///        Signing & Capabilities
///          → Background Modes
///          → Screen Capture
///
///    Note: This option is currently unavailable for this app target.
///
/// 4. Recording Editor
///    iOS 27 introduces the SwiftUI `recordingEditor` modifier. Supplying a
///    binding to the recording file URL automatically presents Apple's built-in
///    editor, allowing users to trim and save the recorded video.
///
@Observable
class ScreenRecorder: NSObject, SCContentSharingPickerObserver {
    /// View Properties
    var recordType: RecordType = .stream
    var isRecording: Bool = false
    var capturesAudio: Bool = true
    var editorURL: URL?
    var cgImageBuffer: CGImage?

    override init() {
        super.init()

        setupContentPicker()
    }

    private var stream: SCStream?
    private var streamOutput: StreamOutput = .init()
    private var screenQueue = DispatchQueue(label: "ScreenQueue")
    private var audioQueue = DispatchQueue(label: "AudioQueue")

    func startRecording() {
        /// showing content picker
        SCContentSharingPicker.shared.isActive = true
        SCContentSharingPicker.shared.present()
    }

    func stopRecording() {
        Task {
            do {
                try await stream?.stopCapture()

                // SCStream does not invoke `stream(_:didStopWithError:)` after a normal
                // `stopCapture()`. That delegate is only called on failure, so perform
                // cleanup manually for the successful stop path.
                if recordType == .stream {
                    resetStream(error: nil, outputURL: nil)
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }

    func resetStream(error: Error?, outputURL: URL?) {
        Task { @MainActor in
            self.stream = nil
            self.isRecording = false
            self.editorURL = outputURL
            self.cgImageBuffer = nil

            self.streamOutput.finishRecording = nil
            self.streamOutput.streamImage = nil

            if let error {
                print(error.localizedDescription)
            }
        }
    }

    func setupStreamAndCapture(_ filter: SCContentFilter, outputURL: URL) {
        Task {
            do {
                let streamConfig = SCStreamConfiguration()
                streamConfig.capturesAudio = capturesAudio
                let stream = SCStream(filter: filter, configuration: streamConfig, delegate: streamOutput)

                if capturesAudio {
                    try stream.addStreamOutput(streamOutput, type: .audio, sampleHandlerQueue: audioQueue)
                }
                try stream.addStreamOutput(streamOutput, type: .screen, sampleHandlerQueue: screenQueue)

                /// add recording type output
                if recordType == .record {
                    let outputConfig = SCRecordingOutputConfiguration()
                    outputConfig.outputURL = outputURL
                    outputConfig.outputFileType = .mov
                    let recordingOutput = SCRecordingOutput(configuration: outputConfig, delegate: streamOutput)
                    try stream.addRecordingOutput(recordingOutput)
                }

                try await stream.startCapture()
                self.stream = stream
                self.isRecording = true

                /// monitoring stream callbacks
                streamOutput.finishRecording = { error in
                    if self.recordType == .record, error == nil {
                        self.resetStream(error: error, outputURL: outputURL)
                    } else {
                        self.resetStream(error: error, outputURL: nil)
                    }
                }

                if recordType == .stream {
                    streamOutput.streamImage = { cgImage in
                        Task { @MainActor in
                            self.cgImageBuffer = cgImage
                        }
                    }
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }

    private func setupContentPicker() {
        var pickerConfiguration = SCContentSharingPickerConfiguration()
        pickerConfiguration.showsCameraControl = true
        pickerConfiguration.showsMicrophoneControl = true

        SCContentSharingPicker.shared.configuration = pickerConfiguration
        SCContentSharingPicker.shared.add(self)
    }

    func contentSharingPicker(_: SCContentSharingPicker, didCancelFor _: SCStream?) {
        /// hiding picker
        SCContentSharingPicker.shared.isActive = true
    }

    func contentSharingPicker(_: SCContentSharingPicker, didUpdateWith filter: SCContentFilter, for _: SCStream?) {
        let outputURL = FileManager.default.temporaryDirectory.appending(path: "REC.mov")

        if FileManager.default.fileExists(atPath: outputURL.path()) {
            try? FileManager.default.removeItem(at: outputURL)
        }

        setupStreamAndCapture(filter, outputURL: outputURL)

        SCContentSharingPicker.shared.isActive = false
    }

    func contentSharingPickerStartDidFailWithError(_ error: any Error) {
        print(error.localizedDescription)
    }
}

class StreamOutput: NSObject, SCStreamOutput, SCStreamDelegate, SCRecordingOutputDelegate {
    var finishRecording: ((Error?) -> Void)?
    var streamImage: ((CGImage) -> Void)?

    private let context = CIContext()

    /// Errors
    func stream(_: SCStream, didStopWithError error: any Error) {
        finishRecording?(error)
    }

    func recordingOutput(_: SCRecordingOutput, didFailWithError error: any Error) {
        finishRecording?(error)
    }

    /// Stream buffer
    func stream(_: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        /// only try extract screen image buffer for this demo
        if type == .screen {
            guard let imageBuffer = sampleBuffer.imageBuffer else { return }
            let ciImage = CIImage(cvImageBuffer: imageBuffer)
            guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
            streamImage?(cgImage)
        }
    }

    func recordingOutputDidFinishRecording(_: SCRecordingOutput) {
        finishRecording?(nil)
    }
}

#Preview {
    ScreenCaptureKitDemo()
}
