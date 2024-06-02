//
//  UICoordinatorPinterestGrid.swift
//  demoApp
// Model fro Pinterest Grid View

/// 1.  extract the swiftUI scrollview and save it here to take a screenshot of the visible region of for animation purpose
/// 2. Rect will be used to save the tapped posts' View Rect for scaling calculations
///
import SwiftUI

@Observable
class UICoordinatorPinterestGrid {
    /// Shared view properties between home and detail view
    var scrollView: UIScrollView = .init(frame: .zero)
    var rect: CGRect = .zero
    var selectedItem : PhotoItem?
    
    /// Animation Layer properties
    var animationLayer: UIImage?
    var animateView: Bool = false
    var hideLayer: Bool = false
    
    /// Root View properties
    var hideRootView: Bool = false
    
    /// Capture snapshot for scrollView's visible region, not the complete scroll region.
    func createVisibleAreaSnapshot() {
        let renderer = UIGraphicsImageRenderer(size: scrollView.bounds.size)
        let image = renderer.image { ctx in
            ctx.cgContext.translateBy(x: -scrollView.contentOffset.x, y: -scrollView.contentOffset.y)
            scrollView.layer.render(in: ctx.cgContext)
        }
        animationLayer = image
    }
}

/// extract UIKit scroll view to SwiftUI scrollView
struct ScrollViewExtractor: UIViewRepresentable {
    var result: (UIScrollView) -> ()

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        
        DispatchQueue.main.async {
            if let scrollView = view.superview?.superview?.superview as? UIScrollView {
                result(scrollView)
            }
        }
        return view
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
       
    }
}
