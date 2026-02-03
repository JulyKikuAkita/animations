//
//  CameraProperties.swift
//  animation
//
//  Created on 2/2/26.

import AVFoundation

struct CameraProperties {
    var session: AVCaptureSession = .init()
    var output: AVCaptureVideoDataOutput = .init()
    var scannedCode: String?
    var permissionState: Permission?

    enum Permission: String {
        case idle = "Not Determined"
        case approved = "Access Granted"
        case denied = "Access Denied"
    }

    static func checkAndAskCameraPermission() async -> Permission? {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            .approved
        case .denied, .restricted:
            .denied
        case .notDetermined:
            /// Requesting camera access
            if await AVCaptureDevice.requestAccess(for: .video) {
                .approved
            } else {
                .denied
            }
        default:
            nil
        }
    }
}
