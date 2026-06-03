//
//  ProgressiveBlurView.swift
//  animation
//
//  Learning points / Demo goals:
//  • Bridge `UIVisualEffectView` into SwiftUI via `UIViewRepresentable`.
//  • Strip the default Core Image filters from a UIKit blur so the view becomes
//    fully transparent — this lets us re-apply our *own* progressive blur on top
//    (e.g. via `.blur(radius:)`) without double-blurring.
//
//  Why this is useful:
//  • SwiftUI's `.background(.ultraThinMaterial)` applies one fixed blur intensity.
//    By neutralising the system blur and adding our own, we can drive blur
//    radius from scroll progress, focus state, etc.
//
//  Key APIs:
//  • `registerForTraitChanges` (iOS 17+) — replacement for the deprecated
//    `traitCollectionDidChange` override; needed to re-strip filters when
//    light/dark mode flips and UIKit recreates the underlying CALayer filters.

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
    /// Tip: `UIVisualEffectView`'s blur lives on its first sublayer's `filters` array
    /// (private API surface but stable in practice). Setting it to `[]` makes the
    /// view fully transparent so callers can re-apply `.blur(radius:)` driven by
    /// state. Must be re-applied on trait changes — see `registerForTraitChanges`.
    private func removeFilters() {
        if let filterLayer = layer.sublayers?.first {
            filterLayer.filters = []
        }
    }
}
