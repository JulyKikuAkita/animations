//
//  InfiniteScrollView.swift
//  animation
//
//  ⚠️  REUSABLE COMPONENT, NOT A STANDALONE DEMO. Consumed by
//      `View/LandingPages/InfiniteHorizontalScrollViewDemo.swift:80`
//      as the seamless-loop scroll engine for the auto-advancing
//      hero carousel. Don't rename without updating that call site.
//
//  Learning point
//  ──────────────
//  Smallest possible "infinite horizontal scroll" container in the
//  project. Generic over `Content: View` — caller passes an HStack
//  of items via the trailing closure, this view duplicates the
//  content to fill the scroll runway and uses the project helper
//  `InfiniteScrollHelper` (background-attached) to manage the
//  wrap-around resets.
//
//  Comparison to siblings:
//    • [[View/Carousel/InfiniteCarouselView]] — duplicates
//      head+tail items in pure SwiftUI via `Group(subviews:)`.
//      Heavier per-cell cost; pure SwiftUI.
//    • [[View/Carousel/InfiniteLoopingScrollView]] — bridges to
//      `UIScrollViewDelegate` to reset content offset directly.
//      Cheapest at runtime; reaches through to UIKit.
//    • THIS FILE — middle ground: SwiftUI-native
//      `Group(subviews:)` measurement + a tiny invisible
//      `InfiniteScrollHelper` background view that handles the
//      wrap math. Caller-friendly: just pass content.
//
//  Key APIs
//  ────────
//  • `Group(subviews:)` (iOS 17.1+) — measures the children so the
//    helper knows how wide one full content unit is.
//  • `onGeometryChange` — picks up the unit width for the helper.
//  • `InfiniteScrollHelper` (project helper at
//    `Helpers/Transition/InfiniteScrollHelper.swift`) —
//    background-attached view that performs the wrap resets.
//
//  How to apply
//  ────────────
//  Drop in whenever you need a horizontal looping carousel and
//  don't want to write the wrap-around math inline. Pass content
//  in the trailing closure exactly as you'd write a normal
//  `HStack { ForEach(items) { ... } }`.
//
//  See also
//  ────────
//  • Helpers/Transition/InfiniteScrollHelper.swift — the engine.
//  • View/LandingPages/InfiniteHorizontalScrollViewDemo.swift —
//    the consumer.
//  • View/Carousel/InfiniteCarouselView.swift,
//    View/Carousel/InfiniteLoopingScrollView.swift — alternative
//    looping techniques in the carousel zoo.
//
import SwiftUI

struct InfiniteScrollView<Content: View>: View {
    var spacing: CGFloat = 10
    @ViewBuilder var content: Content
    /// View Properties
    @State private var contentSize: CGSize = .zero
    var body: some View {
        GeometryReader {
            let size = $0.size

            ScrollView(.horizontal) {
                HStack(spacing: spacing) {
                    Group(subviews: content) { collection in
                        /// Original content
                        HStack(spacing: spacing) {
                            ForEach(collection) { view in
                                view
                            }
                        }
                        .onGeometryChange(for: CGSize.self) {
                            $0.size
                        } action: { newValue in
                            contentSize = .init(width: newValue.width + spacing, height: newValue.height)
                        }

                        /// Repeating content to create infinite lopping effect
                        let averageWidth = contentSize.width / CGFloat(collection.count)
                        let repeatingCount = contentSize.width > 0 ? Int((size.width / averageWidth).rounded()) + 1 : 1

                        HStack(spacing: spacing) {
                            ForEach(0 ..< repeatingCount, id: \.self) { index in
                                let view = Array(collection)[index % collection.count]
                                view
                            }
                        }
                    }
                }
                .background(InfiniteScrollHelper(contentSize: $contentSize, declarationRate: .constant(.fast)))
            }
        }
    }
}
