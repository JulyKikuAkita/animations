//
//  ScannerView.swift
//  DocumentScannerApp
//
// VisionKit API provides access to a viewController called "VNDocumentCameraViewController",
// which provides basic scanning features to capture documents and extract result as image
//
import SwiftUI
import VisionKit

struct ScannerView: UIViewControllerRepresentable {
    var didFinishWithError: (Error) -> ()
    var didCancel: () -> ()
    var didFinish: (VNDocumentCameraScan) -> ()

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {

    }

    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        var parent: ScannerView
        init(parent: ScannerView) {
            self.parent = parent
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFinishWith scan: VNDocumentCameraScan
        ) {
            parent.didFinish(scan)
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.didCancel()
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: any Error) {
            parent.didFinishWithError(error)
        }
    }
}
