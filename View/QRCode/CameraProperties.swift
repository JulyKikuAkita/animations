//
//  CameraProperties.swift
//  animation
//
//  Created on 2/2/26.
//  Helper struct used by `DIRQScannerView.swift` (same folder).
//
//  TODO: Light refactor candidate
//        The `Permission` enum below is isomorphic to
//        `CameraPermission` in `View/CameraInterface/CameraControlView.swift`
//        (idle / approved-or-granted / denied). If we add another
//        camera demo, hoist a single `Helpers/Camera/CameraPermission.swift`
//        and have both folders import it. Don't bother for just two
//        call sites.
//
//  Learning point
//  ──────────────
//  Tiny `struct` (deliberately a value type) bundling the four bits
//  of state every QR-scanning view needs:
//    • `session`  — the `AVCaptureSession` pipeline.
//    • `output`   — `AVCaptureMetadataOutput`, which is the QR/
//      barcode-flavoured output (NOT `AVCapturePhotoOutput`).
//    • `scannedCode` — the result string the delegate writes back.
//    • `permissionState` — drives the UI's "request permission /
//      go to settings" branches.
//
//  `checkAndAskCameraPermission()` is a static helper so callers can
//  bootstrap permission without instantiating the struct first
//  (the struct itself is `@State`-owned by the scanner view).
//
//  Why a struct, not a class?
//  ──────────────────────────
//  `AVCaptureSession` is a reference type, so storing it inside a
//  value type is harmless — every copy of `CameraProperties` shares
//  the SAME underlying session. Using a struct here keeps SwiftUI's
//  `@State` happy without needing `@Observable`. Compare with
//  `Camera` in `View/CameraInterface/CameraControlView.swift`,
//  which DOES need `@Observable` because it has more state to
//  publish.
//
//  See also
//  ────────
//  • DIRQScannerView.swift — the only consumer.
//  • View/CameraInterface/CameraControlView.swift — capture (photo)
//    counterpart; uses `AVCapturePhotoOutput` instead of metadata.
//
import AVFoundation

struct CameraProperties {
    var session: AVCaptureSession = .init()
    var output: AVCaptureMetadataOutput = .init()
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
