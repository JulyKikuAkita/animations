//
//  UIView+Extension.swift
//  animation
//
// Purpose: UIKit `UIView` extensions bridging into SwiftUI features.
//
// What belongs here:
//   - Helpers that operate directly on a UIKit view (not a SwiftUI `View`).
//   - Usually called from inside `UIViewRepresentable`s or from SwiftUI
//     helpers that walk the UIKit hierarchy via `UIApplication`.
//
// What does NOT belong here:
//   - SwiftUI `View` modifiers (→ View+<Concern>.swift files).
//   - CALayer helpers (make a CALayer+Extension.swift if/when needed).
//

import UIKit

extension UIView {
    /// All descendants in the view tree (depth-first).
    func allDescendants() -> [UIView] {
        descendants(ofType: UIView.self)
    }

    /// All descendants matching the given type (depth-first).
    func descendants<T: UIView>(ofType type: T.Type) -> [T] {
        subviews.compactMap { $0 as? T } + subviews.flatMap { $0.descendants(ofType: type) }
    }

    /// Renders this view into a UIImage at the given size.
    /// Used by snapshot-driven transitions (dark-mode fade, hero moves, etc.).
    func image(_ size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            drawHierarchy(in: .init(origin: .zero, size: size), afterScreenUpdates: true)
        }
    }
}
