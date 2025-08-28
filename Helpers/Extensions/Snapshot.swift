//
//  Snapshot.swift
//  animation
//
//  iOS 18
//
// https://www.youtube.com/watch?v=ojdjFn9qjwU
import SwiftUI

extension View {
    @ViewBuilder
    func snapshot(trigger: Bool, onComplete: @escaping (UIImage) -> Void) -> some View {
        modifier(SnapshotModifier(trigger: trigger, onComplete: onComplete))
    }
}

private struct SnapshotModifier: ViewModifier {
    var trigger: Bool
    var onComplete: (UIImage) -> Void

    /// Local view modifier properties
    @State private var view: UIView = .init(frame: .zero)

    func body(content: Content) -> some View {
        if #available(iOS 17, *) {
            content
                .background(ViewExtractor(view: view))
                .compositingGroup()
                .onChange(of: trigger) { _, _ in
                    generateSnapshot()
                }
        } else {
            content
                .background(ViewExtractor(view: view))
                .compositingGroup()
                .onChange(of: trigger) { _ in
                    generateSnapshot()
                }
        }
    }

    private func generateSnapshot() {
        if let superView = view.superview?.superview {
            let renderer = UIGraphicsImageRenderer(size: superView.bounds.size)
            let image = renderer.image { _ in
                superView.drawHierarchy(in: superView.bounds, afterScreenUpdates: true)
            }

            onComplete(image)
        }
    }
}

private struct ViewExtractor: UIViewRepresentable {
    var view: UIView
    func makeUIView(context _: Context) -> some UIView {
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_: UIViewType, context _: Context) {}
}
