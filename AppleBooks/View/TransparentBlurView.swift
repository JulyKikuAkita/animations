//
//  TransparentBlurView.swift
//  demoApp
//
import SwiftUI

// check ProgressiveBlurView in Animation app for variation
struct TransparentBlurView: UIViewRepresentable {
    func makeUIView(context: Context) -> some UIView {
        return CustomTransparentBlurView(effect: .init(style: .systemUltraThinMaterial))
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
    }
}

fileprivate class CustomTransparentBlurView: UIVisualEffectView {
    init(effect: UIBlurEffect) {
        super.init(effect: effect)
        setup()
    }
    
    func setup() {
        removeAllFilters()
        
        /// Registering Trait change
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
                DispatchQueue.main.async {
                self.removeAllFilters()
            }
        }
    }
    
    func removeAllFilters() {
        if let filterLayer = layer.sublayers?.first {
            filterLayer.filters = []
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
