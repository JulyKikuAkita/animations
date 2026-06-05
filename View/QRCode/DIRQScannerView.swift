//
//  DIRQScannerView.swift
//  animation
//
//  Created on 2/1/26.
//  Standalone demo (not wired into the app's demo browser; preview-only).
//  iOS 26+ only — gated by `@available(iOS 26.0, *)` on every type
//  in this file.
//
//  Learning point
//  ──────────────
//  "DIRQ" = **D**ynamic-**I**sland-**R**egion **Q**R scanner: the
//  scanner UI is presented by morphing the iPhone's Dynamic Island
//  into a fullscreen camera viewfinder, then morphs back to the
//  island shape on dismiss. Two distinct techniques stitched
//  together:
//
//    1. AVFoundation QR scanning (the "what works" layer)
//       • `AVCaptureSession` + `AVCaptureMetadataOutput` configured
//         for `.qr` only.
//       • `CameraLayeriOS26View` (`UIViewRepresentable`) hosts the
//         capture session inside a UIView so the preview layer can
//         render — SwiftUI doesn't host `CALayer` directly.
//       • Permission is gated via the static helper on
//         `CameraProperties`; the view branches on
//         `.idle / .approved / .denied` and offers a "Go to Settings"
//         link for denied.
//       • Threading: `session.startRunning()` /
//         `session.stopRunning()` MUST be off-main — both calls hop
//         to a background queue. The session/output read uses
//         `MainActor.run { ... }` because `parent.camera` is
//         MainActor-isolated.
//
//    2. Dynamic Island morph (the "feels iOS 26" layer)
//       • The scanner content sits inside a `ConcentricRectangle`
//         (iOS 26) sized to match the Dynamic Island pill at rest
//         (120×36) and animated to the expanded scanner rect
//         (~screenWidth × screenWidth).
//       • `topOffset` calculation accounts for whether the device
//         has a Dynamic Island (safeArea.top ≥ 59pt) — keeps the
//         pill anchored to the actual island on iPhone 15 Pro+, and
//         mocks the position on older safe-area devices.
//       • `fullScreenCover` is opened with `Transaction.disablesAnimations`
//         so the cover itself doesn't animate; ALL motion comes from
//         the manual `withAnimation(.interpolatingSpring(...))`
//         around `isExpanding`.
//       • Dismiss flow: animation runs first → `onDisappear` of an
//         invisible Rectangle inside the expanding view fires →
//         flips `showContent = false` → outer ZStack's
//         `.transition(.identity)` lets the cover dismiss without
//         a second animation.
//
//  Key APIs
//  ────────
//  • `AVCaptureMetadataOutput` + `AVMetadataObject.ObjectType.qr` —
//    the QR-flavoured output; restrict types early so the delegate
//    isn't woken on faces/barcodes.
//  • `AVCaptureMetadataOutputObjectsDelegate` (Coordinator) — the
//    delegate that publishes `scannedCode` back into SwiftUI state.
//  • `ConcentricRectangle(corners: .concentric(minimum: .fixed(30)))`
//    — iOS 26 shape that automatically rounds to match nested
//    geometry; load-bearing for the morph fitting the island
//    silhouette.
//  • `phaseAnimator([false, true]) { ... }` — drives the scanning
//    line's perpetual top↔bottom shimmer. Self-restarting; no Timer.
//  • `Transaction(disablesAnimations: true) + withTransaction { ... }`
//    — the trick that suppresses `fullScreenCover`'s default
//    transition.
//
//  How to apply
//  ────────────
//  Use the morph pattern whenever a CHROME element (status bar,
//  Dynamic Island, navigation bar) is the natural source for an
//  expanded view. The QR-specific bits are isolated in
//  `CameraLayeriOS26View.Coordinator.setupCamera()` — swap that
//  closure for face detection, text recognition, etc., and the
//  enclosing morph still works.
//
//  See also
//  ────────
//  • CameraProperties.swift — the small AVFoundation state bag.
//  • View/CameraInterface/CameraControlView.swift — sibling demo
//    for *capture* (photo) using `AVCapturePhotoOutput`. Different
//    intent (take a picture vs. scan metadata), so the folders stay
//    separate even though both touch AVFoundation.
//  • View/CameraInterface/PicoCamPart1DemoView.swift — also uses a
//    Dynamic-Island-anchored frame for a different UX (instant-camera
//    print frame).
//
import AVFoundation
import SwiftUI

@available(iOS 26.0, *)
struct DIRQScannerDemoView: View {
    @State private var showScanner: Bool = false
    var body: some View {
        NavigationStack {
            List {
                Button("Show Scanner") {
                    showScanner.toggle()
                }
            }
            .navigationTitle("QR Scanner")
            .qrscanner(isScanning: $showScanner) { _ in
            }
        }
    }
}

@available(iOS 26.0, *)
extension View {
    @ViewBuilder
    func qrscanner(isScanning: Binding<Bool>, onScan: @escaping (String) -> Void) -> some View {
        modifier(QRScannerViewModifier(isScanning: isScanning, onScan: onScan))
    }
}

@available(iOS 26.0, *)
private struct QRScannerViewModifier: ViewModifier {
    @Binding var isScanning: Bool
    var onScan: (String) -> Void
    /// Modifier Properties
    @State private var showFullScreenCover: Bool = false
    func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: $showFullScreenCover) {
                DIRQScannerView {
                    isScanning = false
                    Task { @MainActor in
                        showFullScreenCoverWithoutAnimation(false)
                    }
                } onScan: { code in
                    onScan(code)
                }
                .presentationBackground(.clear)
            }
            .onChange(of: isScanning) { _, newValue in
                if newValue {
                    showFullScreenCoverWithoutAnimation(true)
                }
            }
    }

    private func showFullScreenCoverWithoutAnimation(_ status: Bool) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            showFullScreenCover = status
        }
    }
}

@available(iOS 26.0, *)
struct DIRQScannerView: View {
    var onClose: () -> Void
    var onScan: (String) -> Void
    /// View Properties
    @State private var isInitialized: Bool = false
    @State private var showContent: Bool = false
    @State private var isExpanding: Bool = false
    @State private var camera: CameraProperties = .init()
    @Environment(\.openURL) private var openURL
    var body: some View {
        GeometryReader {
            let size = $0.size
            let safeArea = $0.safeAreaInsets

            /// Dynamic Island
            let haveDynamicIsland: Bool = safeArea.top >= 59
            let dynamicIslandWidth: CGFloat = 120
            let dynamicIslandHeight: CGFloat = 36
            let topOffset: CGFloat = haveDynamicIsland ? (11 + max(safeArea.top - 59, 0)) : (isExpanding ? (safeArea.top) : -50)

            let expandedWidth: CGFloat = size.width - 30
            let expandedHeight: CGFloat = expandedWidth

            ZStack(alignment: .top) {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .contentShape(.rect)
                    .onTapGesture {
                        toggle(false)
                    }
                /// Scanner Animated view
                if showContent {
                    ConcentricRectangle(
                        corners: .concentric(minimum: .fixed(30)),
                        isUniform: true
                    )
                    .fill(.black)
                    .overlay {
                        GeometryReader {
                            let cameraSize = $0.size
                            scannerView(cameraSize)
                        }
                        .overlay(alignment: .bottom) {
                            Text("Scan your QR code")
                                .font(.caption2)
                                .foregroundStyle(.white.secondary)
                                .lineLimit(1)
                                .fixedSize()
                                .offset(y: 25)
                        }
                        .padding(80)
                        .compositingGroup()
                        .blur(radius: isExpanding ? 0 : 20)
                        .opacity(isExpanding ? 1 : 0)
                        .geometryGroup()
                        .offset(y: nonDynamicIslandHaveSpacing || haveDynamicIsland ? 0 : 10)
                    }
                    .frame(width: isExpanding ? expandedWidth : dynamicIslandWidth,
                           height: isExpanding ? expandedHeight : dynamicIslandHeight)
                    .offset(y: topOffset)
                    .background {
                        if isExpanding {
                            Rectangle()
                                .fill(.clear)
                                .onDisappear {
                                    /// triggered when the isExpanding animation completes
                                    showContent = false
                                }
                        }
                    }
                    .transition(.identity)
                    .onDisappear {
                        /// when animation completed -> it calls on disappear and trigger onClose
                        onClose()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .ignoresSafeArea()
            .task {
                guard !isInitialized else { return }
                isInitialized = true
                showContent = true
                try? await Task.sleep(for: .seconds(0.05))
                toggle(true)
                camera.permissionState = await CameraProperties.checkAndAskCameraPermission()
            }
            .onChange(of: camera.scannedCode) { _, newValue in
                if let newValue {
                    onScan(newValue)
                    toggle(false)
                }
            }
        }
        .statusBarHidden()
    }

    @ViewBuilder
    private func scannerView(_ size: CGSize) -> some View {
        let shape = RoundedRectangle(cornerRadius: size.width * 0.05, style: .continuous)

        ZStack {
            /// Camera AVSessionLayer View
            if let permissionState = camera.permissionState {
                if permissionState == .approved {
                    CameraLayeriOS26View(size: size, camera: $camera)
                        .overlay(alignment: .top) {
                            scannerAnimation(size.height)
                        }
                }

                if permissionState == .denied {
                    /// link to settings url to update camera settings
                    VStack(spacing: 4) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: size.width * 0.15))
                            .foregroundStyle(.white)

                        Text("Permission denied")
                            .font(.caption)
                            .foregroundStyle(.red)

                        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                            Button("Go to Settings") {
                                openURL(settingsURL)
                            }
                            .font(.caption)
                            .foregroundStyle(.white)
                            .underline()
                        }
                    }
                    .fixedSize()
                }
            }
            shape
                .stroke(.white, lineWidth: 2)
        }
        .frame(width: size.width, height: size.height)
        .clipShape(shape)
    }

    private func scannerAnimation(_ height: CGFloat) -> some View {
        Rectangle()
            .fill(.white)
            .frame(height: 2.5)
            .phaseAnimator([false, true], content: { content, isScanning in
                content
                    .shadow(color: .black.opacity(0.8), radius: 8, x: 0, y: isScanning ? 15 : -15)
                    .offset(y: isScanning ? height : 0)
            }, animation: { _ in
                .easeInOut(duration: 0.85).delay(0.1)
            })
    }

    private func toggle(_ status: Bool) {
        withAnimation(.iSpring()) {
            isExpanding = status
        }

        if !status {
            // stop the session on a background queue to avoid blocking the UI thread
            DispatchQueue.global(qos: .background).async {
                camera.session.stopRunning()
            }
        }
    }

    var nonDynamicIslandHaveSpacing: Bool {
        false
    }
}

private struct CameraLayeriOS26View: UIViewRepresentable {
    var size: CGSize
    @Binding var camera: CameraProperties
    func makeUIView(context _: Context) -> UIView {
        let view = UIView(frame: .init(origin: .zero, size: size))
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_: UIView, context _: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var parent: CameraLayeriOS26View
        init(parent: CameraLayeriOS26View) {
            self.parent = parent
            super.init()
            setupCamera()
        }

        func setupCamera() {
            // run the heavy lifting in an async Task so we can hop to MainActor when we need to read/write camera
            Task {
                // read the camera properties on MainActor (because `parent.camera` is MainActor-isolated)
                let (session, output): (AVCaptureSession, AVCaptureMetadataOutput) = await MainActor.run {
                    (parent.camera.session, parent.camera.output)
                }

                // early exit if already running
                guard !session.isRunning else { return }

                // find device (this is fine off-main)
                guard let device = AVCaptureDevice.DiscoverySession(
                    deviceTypes: [.builtInWideAngleCamera],
                    mediaType: .video,
                    position: .back
                ).devices.first else { return }

                do {
                    let input = try AVCaptureDeviceInput(device: device)

                    guard session.canAddInput(input), session.canAddOutput(output) else { return }

                    session.beginConfiguration()
                    session.addInput(input)
                    session.addOutput(output)

                    // fully-qualified type so the compiler knows what `.qr` means
                    output.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]

                    // fully-qualified queue reference so `.main` isn't ambiguous
                    output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)

                    session.commitConfiguration()

                    // start the session on a background queue to avoid blocking the UI thread
                    DispatchQueue.global(qos: .background).async {
                        session.startRunning()
                    }
                } catch {
                    // handle error if needed
                    print(error.localizedDescription)
                }
            }
        }

        /// fetch QR code
        func metadataOutput(_: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from _: AVCaptureConnection) {
            if let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
               let code = object.stringValue
            {
                guard parent.camera.scannedCode == nil else { return }
                parent.camera.scannedCode = code
            }
        }
    }
}

@available(iOS 26.0, *)
#Preview {
    DIRQScannerDemoView()
}
