//
//  ProgressiveBlurView.swift
//  animation

import SwiftUI

struct ProgressiveBlurView: UIViewRepresentable {
    func makeUIView(context _: Context) -> CustomBlurView {
        let view = CustomBlurView()
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_: UIViewType, context _: Context) {}
}

class CustomBlurView: UIVisualEffectView {
    init() {
        super.init(effect: UIBlurEffect(style: .systemUltraThinMaterial))

        removeFilters()

        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
            DispatchQueue.main.async {
                self.removeFilters()
            }
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Removing All Filters
    private func removeFilters() {
        if let filterLayer = layer.sublayers?.first {
            filterLayer.filters = [] // removing all the filters from a view makes it a complete transparent view
            // then apply a progressive blur effect
        }
    }
}
