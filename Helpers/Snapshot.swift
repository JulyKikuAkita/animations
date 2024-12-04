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
    func snapshot(trigger: Bool, onComplete: @escaping (UIImage) -> ()) -> some View {
        self
            .modifier(SnapshotModifier(trigger: trigger, onComplete: onComplete))
    }
}

fileprivate struct SnapshotModifier: ViewModifier {
    var trigger: Bool
    var onComplete: (UIImage) -> ()
    
    /// Local view modifier properties
    @State private var view: UIView = .init(frame: .zero)
    
    func body(content: Content) -> some View {
        if #available(iOS 17, *) {
            content
                .background(ViewExtractor(view: view))
                .compositingGroup()
                .onChange(of: trigger) { oldValue, newValue in
                    generateSnapshot()
                }
        } else {
            content
                .background(ViewExtractor(view: view))
                .compositingGroup()
                .onChange(of: trigger) { newValue in
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

fileprivate struct ViewExtractor: UIViewRepresentable {
    var view: UIView
    func makeUIView(context: Context) -> some UIView {
        view.backgroundColor = .clear
        return view
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
    }

}
