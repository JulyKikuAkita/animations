//
//  ScreenCaptureKit+MockFor26.swift
//  animation
//
//  Created on 6/27/26.
// Remove once Xcode 27 is the minimum supported version.

#if !canImport(ScreenCaptureKit)

    import CoreGraphics
    import CoreMedia
    import Foundation

    // MARK: - Types

    final class SCStream: NSObject {
        convenience init(filter _: SCContentFilter, configuration _: SCStreamConfiguration, delegate _: SCStreamDelegate?) {
            self.init()
        }

        func addStreamOutput(_: SCStreamOutput, type _: SCStreamOutputType, sampleHandlerQueue _: DispatchQueue) throws {
            // no-op
        }

        func addRecordingOutput(_: SCRecordingOutput) throws {}

        func startCapture() async throws {}

        func stopCapture() async throws {}
    }

    final class SCRecordingOutput: NSObject {
        var configuration: SCRecordingOutputConfiguration
        var delegate: StreamOutput
        init(configuration: SCRecordingOutputConfiguration, delegate: StreamOutput) {
            self.configuration = configuration
            self.delegate = delegate
        }
    }

    final class SCRecordingOutputConfiguration {
        init() {}
        var outputURL: URL?
        var outputFileType: StreamOutputType = .mov
    }

    enum StreamOutputType {
        case mov
    }

    // MARK: - Content Filter

    final class SCContentFilter {
        init() {}
    }

    // MARK: - Stream Configuration

    final class SCStreamConfiguration {
        var capturesAudio = false
        init() {}
    }

    enum SCStreamOutputType {
        case screen
        case audio
        case microphone
    }

    // MARK: - Protocols

    protocol SCStreamOutput: AnyObject {
        func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType)
    }

    protocol SCStreamDelegate: AnyObject {
        func stream(_ stream: SCStream, didStopWithError error: any Error)
    }

    protocol SCRecordingOutputDelegate: AnyObject {
        func recordingOutput(_ recordingOutput: SCRecordingOutput, didFailWithError error: any Error)
        func recordingOutputDidFinishRecording(_ recordingOutput: SCRecordingOutput)
    }

    protocol SCContentSharingPickerObserver: AnyObject {
        func contentSharingPicker(
            _ picker: SCContentSharingPicker,
            didCancelFor stream: SCStream?
        )

        func contentSharingPickerStartDidFailWithError(
            _ error: any Error
        )
    }

    final class SCContentSharingPickerConfiguration {
        var showsCameraControl = false
        var showsMicrophoneControl = false

        init() {}
    }

    final class SCContentSharingPicker {
        static let shared = SCContentSharingPicker()

        var configuration = SCContentSharingPickerConfiguration()
        var isActive = false

        func add(_: any SCContentSharingPickerObserver) {}

        func remove(_: any SCContentSharingPickerObserver) {}

        func present() {}
    }

#endif
