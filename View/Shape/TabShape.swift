//
//  TabShape.swift
//  animation
//
//  Learning point
//  ──────────────
//  Custom `Shape` for a tab bar that has a notch/dip carved out around
//  the active tab — think TikTok/Twitter-style "indented" tab bar where
//  the selected icon sits in a curved cutout. The notch position is
//  driven by `midpoint`, which is the X-coordinate of the active tab's
//  centre.
//
//  The reusable trick: animatable `Shape`
//  ──────────────────────────────────────
//  Conforming `animatableData` to `midpoint` is what makes the notch
//  *slide* between tabs instead of jumping. SwiftUI re-evaluates
//  `path(in:)` every frame with an interpolated `midpoint` value, and
//  the curve gets redrawn at each intermediate position. Without this,
//  even `withAnimation { midpoint = ... }` would produce a hard cut.
//
//  How the path is built
//  ─────────────────────
//    1. Draw a full `Rectangle` covering `rect` — that's the bar.
//    2. Move to `(midpoint - 60, 0)` — start of the notch on the bar's
//       top edge.
//    3. Two cubic Bézier curves form the dip:
//         • First curve: down/up from -60 to midpoint, dipping to y=-20.
//         • Second curve: midpoint back to +60, returning to y=0.
//       The control points (midpoint ± 25, 0/-20) shape the curve's
//       sharpness — bring control1/control3's X closer to midpoint for
//       a tighter notch.
//
//  `viewPosition(completion:)`
//  ───────────────────────────
//  The companion modifier reports a view's global frame to the caller
//  via an `OffsetKey` `PreferenceKey`. The tab bar uses this to read
//  each tab button's centre X, then animates `midpoint` toward that
//  value — closing the loop between layout and shape.
//
//  Key APIs
//  ────────
//  • `Shape` + `animatableData` — the canonical way to animate a
//    custom drawing primitive.
//  • `Path.addCurve(to:control1:control2:)` — cubic Bézier; control
//    points dictate "how curvy" the segment is.
//  • `PreferenceKey` (`OffsetKey` lives elsewhere in the project) —
//    pre-iOS-16 way to publish geometry up the tree. iOS 16+ can use
//    `onGeometryChange` for the same effect with less ceremony.
//
//  How to apply
//  ────────────
//  Use whenever you want a notched/cutout custom container shape
//  whose cutout position is data-driven (selected tab, hovered chip,
//  active drag handle). The animatable-Shape pattern generalises to
//  morphing any path between two states.
//
//  See also
//  ────────
//  • View/CustomTabBar/* — likely call sites for this shape.
//  • WaveFormRectangleShape.swift — sister `Shape` in this folder
//    using rectangles instead of curves.
//

import SwiftUI

/// Custom Tab Shape
struct TabShape: Shape {
    var midpoint: CGFloat

    /// adding shape animation
    var animatableData: CGFloat {
        get { midpoint }
        set { midpoint = newValue }
    }

    func path(in rect: CGRect) -> Path {
        Path { path in
            /// First drawing a rectangle shape
            path.addPath(Rectangle().path(in: rect))
            // Tip: tweak the four magic numbers below to reshape the notch:
            //   • `±60` — half-width of the notch opening on the bar's top edge.
            //   • `-20` — depth of the dip (negative = above the bar).
            //   • `±25` (control points X) — pull-in distance; smaller = tighter,
            //     more square-ish curve. Larger = wider, gentler lobes.
            path.move(to: .init(x: midpoint - 60, y: 0))

            let to = CGPoint(x: midpoint, y: -20)
            let control1 = CGPoint(x: midpoint - 25, y: 0)
            let control2 = CGPoint(x: midpoint - 25, y: -20)

            path.addCurve(to: to, control1: control1, control2: control2)

            let to1 = CGPoint(x: midpoint + 60, y: 0)
            let control3 = CGPoint(x: midpoint + 25, y: -20) // try + 30 for x axis
            let control4 = CGPoint(x: midpoint + 25, y: 0)

            path.addCurve(to: to1, control1: control3, control2: control4)
        }
    }
}

/// Use OffsetKey to calculate the curve of tab
extension View {
    @ViewBuilder
    func viewPosition(completion: @escaping (CGRect) -> Void) -> some View {
        overlay {
            GeometryReader {
                let rect = $0.frame(in: .global)

                Color.clear
                    .preference(key: OffsetKey.self, value: rect)
                    .onPreferenceChange(OffsetKey.self, perform: completion)
            }
        }
    }
}

#Preview {
    TabShape(midpoint: 100)
}
