//
//  ImageCarouselView.swift
//  animation
//
//  Standalone demo (not wired into the app's demo browser; preview-only).
//
//  Learning point
//  ──────────────
//  This file's main contribution is a REUSABLE generic carousel —
//  `CustomCarousel<Content, Data>` — wrapped behind a `Config` knob
//  so callers don't have to hand-roll the scroll-progress math each
//  time. The demo (`ImageCarouselDemoView`) is thin; the helper is
//  the takeaway.
//
//  What `CustomCarousel` does:
//    • Lays items out in a horizontal `LazyHStack` with
//      `.scrollTargetLayout()` + `.viewAligned`.
//    • Per item, a `visualEffect` reads scroll-space position and
//      derives a 0...1 progress relative to viewport centre.
//    • That progress drives `scaleEffect` and `opacity` so off-centre
//      cards shrink and fade.
//    • `Config` exposes spacing, scale, opacity, card size — i.e.
//      the dials you'd normally rewrite each time.
//
//  Key APIs
//  ────────
//  • Generic `View where Data: RandomAccessCollection, Data.Element:
//    Identifiable` + `@ViewBuilder var content: (Data.Element) -> C` —
//    the standard reusable-carousel signature.
//  • `.visualEffect { content, proxy in ... }` — the per-item
//    progress→scale/opacity hook.
//  • `.scrollPosition(id:)` — two-way binding so the parent knows
//    which card is active.
//  • Nested `Config` struct — preferred over a long parameter list.
//
//  How to apply
//  ────────────
//  Reach for this BEFORE hand-rolling carousel scroll math; copying
//  `CustomCarousel` is faster than re-deriving. Tweak `Config` for
//  shrinkage / gap / size; swap content via the trailing closure.
//
//  See also
//  ────────
//  • CardCarouselWithScrollTransitionsAPI.swift — same effect via
//    `.scrollTransition(.interactive)` (iOS 18) instead of
//    `visualEffect` (iOS 17). Compare the two for which API to use.
//  • CircularCarouselSliderView.swift — vertical version of a similar
//    progress→offset pattern.
//
import SwiftUI

struct ImageCarouselDemoView: View {
    @State private var activeID: UUID?

    var body: some View {
        NavigationStack {
            VStack {
                CustomCarousel(
                    config: .init(
                        hasOpacity: true,
                        hasScale: true,
                        cardWidth: 200,
                        minimumCardWidth: 30
                    ),
                    data: stackCards,
                    selection: $activeID
                ) { item in
                    Image(item.profilePicture)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
                .frame(height: 180)
            }
            .navigationTitle("Cover Carousel")
        }
    }
}

struct CustomCarousel<Content: View, Data: RandomAccessCollection>: View where Data.Element: Identifiable {
    var config: Config
    var data: Data
    @Binding var selection: Data.Element.ID?
    @ViewBuilder var content: (Data.Element) -> Content
    var body: some View {
        GeometryReader {
            let size = $0.size

            ScrollView(.horizontal) {
                /// if use lazyHStack + offset modifier, the view at both side might not be visible until
                /// itemView reaches the screen space
                HStack(spacing: config.spacing) {
                    ForEach(data) { item in
                        itemView(item)
                    }
                }
                .scrollTargetLayout()
            }
            /// position in the center of screen
            .safeAreaPadding(.horizontal, max((size.width - config.cardWidth) / 2, 0))
            /// carousel effect
            .scrollPosition(id: $selection)
            .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
            .scrollIndicators(.hidden)
        }
    }

    @ViewBuilder
    func itemView(_ item: Data.Element) -> some View {
        GeometryReader { proxy in
            let size = proxy.size

            let minX = proxy.frame(in: .scrollView(axis: .horizontal)).minX
            let progress = minX / (config.cardWidth + config.spacing)
            let minimumCardWidth = config.minimumCardWidth

            let diffWidth = config.cardWidth - minimumCardWidth
            let reducingWidth = progress * diffWidth
            /// limiting diffWidth as the max value
            let cappedWidth = min(reducingWidth, diffWidth)

            let resizedFrameWidth = size.width - (
                minX > 0 ? cappedWidth : min(-cappedWidth, diffWidth)
            )
            let negativeProgress = max(-progress, 0)

            let scaleValue = config.scaleValue * abs(progress)
            let opacityValue = config.opacityValue * abs(progress)

            content(item)
                .frame(width: size.width, height: size.height)
                .frame(width: resizedFrameWidth)
                .opacity(config.hasOpacity ? 1 - opacityValue : 1)
                .scaleEffect(config.hasScale ? 1 - scaleValue : 1)
                .mask {
                    let hasScale = config.hasScale
                    let scaledHeight = (1 - scaleValue) * size.height
                    RoundedRectangle(cornerRadius: config.cornerRadius)
                        .frame(height: hasScale ? max(scaledHeight, 0) : size.height)
                }
                .clipShape(.rect(cornerRadius: config.cornerRadius))
                .offset(x: -reducingWidth)
                .offset(x: min(progress, 1) * diffWidth)
                .offset(x: negativeProgress * diffWidth)
        }
        .frame(width: config.cardWidth)
    }

    struct Config {
        var hasOpacity: Bool = false
        var opacityValue: CGFloat = 0.4
        var hasScale: Bool = false
        var scaleValue: CGFloat = 0.2

        var cardWidth: CGFloat = 150
        var spacing: CGFloat = 10
        var cornerRadius: CGFloat = 15
        var minimumCardWidth: CGFloat = 40
    }
}

#Preview {
    ImageCarouselDemoView()
}
