//
//  PageIndicatorView.swift
//  animation
//
// SwiftUI learning notes — key takeaways in this file:
//
// 1. `GeometryReader` exposes this view's own size/frame, but the iOS 17+
//    `bounds(of: .scrollView(axis:))` + `frame(in: .scrollView(axis:))`
//    APIs let a child view read the *ancestor* ScrollView's metrics — that's
//    what makes scroll-driven effects possible without `@Binding` plumbing.
// 2. Scroll progress is just a ratio: `-minX / scrollViewWidth`. Split its
//    integer and fractional parts to get "which page we're on" and "how far
//    into the next one we've scrolled" — the fractional part drives animation.
// 3. A common SwiftUI idiom: use a clear shape + `.frame` to *reserve space*,
//    then draw the visible content via `.overlay`. Changing the frame animates
//    layout (width here) while the overlay follows along.
// 4. `.offset(x: -minX)` cancels out the parent's scroll offset, keeping this
//    view visually pinned even though it's laid out inside the ScrollView.
//
import SwiftUI

/// A capsule-style page indicator that animates between pages as a horizontal
/// scroll view moves. Place it *inside* the same horizontal ScrollView whose
/// pages it's indicating — it reads that scroll view's position via
/// `GeometryProxy.bounds(of:)` / `frame(in:)`.
struct PageIndicatorView: View {
    var activeTint: Color = .primary
    var inactiveTint: Color = .primary.opacity(0.15)
    /// If true, the active capsule crossfades in color as it morphs.
    /// If false, the active color stays solid and only the width animates.
    var opacityEffect: Bool = false
    /// If true, clamps progress to [0, totalPages-1] so overscroll past the
    /// first/last page doesn't push the indicator past its bounds.
    var clipEdges: Bool = false

    var body: some View {
        // `GeometryReader` hands us a `GeometryProxy` (`$0`) describing this
        // view's own geometry. We use it to query BOTH this view and the
        // ancestor ScrollView.
        GeometryReader {
            // This view's total width — we placed it inside the paging
            // HStack, so its width equals (scrollViewWidth × totalPages).
            let width = $0.size.width

            // `bounds(of: .scrollView(axis:))` returns the ancestor horizontal
            // ScrollView's visible bounds, or nil if there isn't one. The
            // `scrollViewWidth > 0` guard avoids a divide-by-zero on first layout.
            if let scrollViewWidth = $0.bounds(
                of: .scrollView(axis: .horizontal)
            )?.width, scrollViewWidth > 0 {
                // `minX` in the scrollView's coordinate space is negative as
                // the user scrolls right — that's why we negate it below.
                let minX = $0.frame(in: .scrollView(axis: .horizontal)).minX
                let totalPages = Int(width / scrollViewWidth)

                // --- Progress math ---
                // `freeProgress` can go negative (pull-to-left overscroll)
                // or exceed `totalPages-1` (pull-to-right overscroll).
                let freeProgress = -minX / scrollViewWidth
                let clippedProgress = min(
                    max(freeProgress, 0.0),
                    CGFloat(totalPages - 1)
                )
                let progress = clipEdges ? clippedProgress : freeProgress

                // Split progress into "which page" (int) and "how far" (frac).
                // e.g. progress = 1.3 → activeIndex = 1, nextIndex = 2,
                //      indicatorProgress = 0.3
                let activeIndex = Int(progress)
                let nextIndex = Int(progress.rounded(.awayFromZero))
                let indicatorProgress = progress - CGFloat(activeIndex)

                // Interpolate how many extra pixels to add to each of the
                // two adjacent capsules. 18pt = base capsule (8) + spacing (10).
                // At progress 0.0 → current gets +18, next gets +0.
                // At progress 1.0 → current gets +0,  next gets +18.
                let currentPageWidth = 18 - (indicatorProgress * 18)
                let nextPageWidth = indicatorProgress * 18

                HStack(spacing: 10) {
                    // `ForEach(0..<N, id: \.self)` — fine for fixed-size
                    // ranges. For dynamic collections, prefer `Identifiable`.
                    ForEach(0 ..< totalPages, id: \.self) { index in
                        Capsule()
                            .fill(.clear) // invisible — only used for sizing
                            .frame(
                                width: 8 + (
                                    activeIndex == index ? currentPageWidth
                                        : nextIndex == index ? nextPageWidth : 0),
                                height: 8
                            )
                            // `.overlay` draws on top of the clear shape at
                            // exactly the clear shape's size → the visible
                            // capsules animate in lockstep with the frame.
                            .overlay {
                                ZStack {
                                    Capsule()
                                        .fill(inactiveTint)

                                    // Active tint is either always visible
                                    // (solid mode) or crossfades between the
                                    // current and next indicator.
                                    Capsule()
                                        .fill(activeTint)
                                        .opacity(opacityEffect ? activeIndex == index ? 1 - indicatorProgress
                                            : nextIndex == index ? indicatorProgress : 0 : 1)
                                }
                            }
                    }
                }
                // Pin the HStack to one page's width and cancel the scroll
                // offset. The indicator lives inside the ScrollView but
                // appears to stay put while pages slide past.
                .frame(width: scrollViewWidth)
                .offset(x: -minX)
            }
        }
        .frame(height: 30)
    }
}

#Preview {
    PageIndicatorView()
}
