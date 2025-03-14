//
//  CameraControlView.swift
//  animation
// Only runs on real iPhone 18 devices (with camera control button)
// Add camera privacy property at the info.list
import AVKit
import SwiftUI

enum CameraPermission: String {
    case granted = "Permission Granted"
    case idle = "Not Decided"
    case denied = "Permission Denied"
}

@MainActor
@Observable
class Camera: NSObject, AVCaptureSessionControlsDelegate {
    /// Camera properties
    private let queue: DispatchSerialQueue = .init(label: "nanachi.animation.cameraControlAPI.sessionQueue")
    let session: AVCaptureSession = .init()
    let cameraPosition: AVCaptureDevice.Position = .back
    let cameraOutput: AVCapturePhotoOutput = .init()
    let videoGravity: AVLayerVideoGravity = .resizeAspectFill
    var permission: CameraPermission = .idle

    override init() {
        super.init()
    }

    /// Check and ask for camera permission
    private func checkCameraPermission() {
        Task {
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                permission = .granted
                setupCamera()
            case .notDetermined:
                /// Asking for permission
                if await AVCaptureDevice.requestAccess(for: .video) {
                    setupCamera()
                }
            case .denied, .restricted:
                permission = .denied
            @unknown default:
                break
            }
        }
    }

    private func setupCamera() {
        do {
            session.beginConfiguration()

            guard let device = AVCaptureDevice.DiscoverySession(
                deviceTypes: [.builtInWideAngleCamera],
                mediaType: .video,
                position: cameraPosition
            ).devices.first else {
                print("Couldn't find back camera")

                session.commitConfiguration()
                return
            }

            let input = try AVCaptureDeviceInput(device: device)
            guard session.canAddInput(input), session.canAddOutput(cameraOutput) else {
                print("Couldn't add camera output")
                session.commitConfiguration()
                return
            }

            session.addInput(input)
            session.addOutput(cameraOutput)
            setupCameraControl(device)
            session.commitConfiguration()
            startSession()
        } catch {
            print(error.localizedDescription)
        }
    }

    func startSession() {
        guard !session.isRunning else { return }
        /// Session start/stop must run on background thread not on the main thread
        Task.detached(priority: .background) {
            await self.session.startRunning()
        }
    }

    func stopSession() {
        guard session.isRunning else { return }
        /// Session start/stop must run on background thread not on the main thread
        Task.detached(priority: .background) {
            await self.session.stopRunning()
        }
    }

    /// Set up camera control action for iPhone 16+ models
    private func setupCameraControl(_: AVCaptureDevice) {
        /// Checking if the device is eligible for camera control
        guard session.supportsControls else { return }
        session.setControlsDelegate(self, queue: queue)

        /// Removing any previously added controls, if any
        for control in session.controls {
            session.removeControl(control)
        }

        /// Default control
        let zoomControl = AVCaptureSlider("Zoom", symbolName: "", in: -0.5 ... 1)
        zoomControl.setActionQueue(queue) { progress in
            print(progress)
            /// Update Camera
        }

        let filters: [String] = ["None", "B/W", "Vivid", "Comic", "Humid"]
        let filterControl = AVCaptureIndexPicker(
            "Filters",
            symbolName: "camera.filters",
            localizedIndexTitles: filters
        )
        filterControl.setActionQueue(queue) { index in
            print("Selected Filter: ", filters[index])
            /// Update Camera
        }

        let controls: [AVCaptureControl] = [zoomControl, filterControl]
        for control in controls {
            /// Always check whether the control can be added to a session
            if session.canAddControl(zoomControl) {
                session.addControl(zoomControl)
            } else {
                print("Control can't be added")
            }
        }
    }

    /// Camera control protocols
    nonisolated func sessionControlsDidBecomeActive(_: AVCaptureSession) {}

    nonisolated func sessionControlsWillEnterFullscreenAppearance(_: AVCaptureSession) {}

    nonisolated func sessionControlsWillExitFullscreenAppearance(_: AVCaptureSession) {}

    nonisolated func sessionControlsDidBecomeInactive(_: AVCaptureSession) {}

    func capturePhoto() {
        print("Capturing photo")
    }
}

struct CameraControlView: View {
    var camera: Camera = .init()
    @Environment(\.scenePhase) private var scene

    var body: some View {
        GeometryReader {
            let size = $0.size
            CameraLayerView(size: size)
        }
        .environment(camera)
        .onChange(of: scene) { _, newValue in
            if newValue == .active {
                camera.startSession()
            } else {
                camera.stopSession()
            }
        }
    }
}

struct CameraLayerView: UIViewRepresentable {
    var size: CGSize
    @Environment(Camera.self) private var camera

    func makeUIView(context _: Context) -> some UIView {
        let frame = CGRect(origin: .zero, size: size)

        let view = UIView(frame: frame)
        view.backgroundColor = .clear
        view.clipsToBounds = true

        /// AVCamera Layer
        let layer = AVCaptureVideoPreviewLayer(session: camera.session)
        layer.videoGravity = camera.videoGravity
        layer.frame = frame
        layer.masksToBounds = true

        view.layer.addSublayer(layer)
        setupCameraInteraction(view)

        return view
    }

    func updateUIView(_: UIViewType, context _: Context) {}

    func setupCameraInteraction(_ view: UIView) {
        let cameraControlInteraction = AVCaptureEventInteraction { event in
            if event.phase == .ended {
                /// onEnd click the camera button
                camera.capturePhoto()
            }
        }

        view.addInteraction(cameraControlInteraction)
    }
}

#Preview {
    CameraControlView()
}
