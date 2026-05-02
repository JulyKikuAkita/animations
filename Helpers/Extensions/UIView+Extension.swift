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
    /// Flattens all descendants into a single array (depth-first).
    func allSubViews() -> [UIView] {
        var result: [UIView] = subviews.compactMap(\.self)
        for subview in subviews {
            result.append(contentsOf: subview.allSubViews())
        }
        return result
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
