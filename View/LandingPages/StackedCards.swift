//
//  StackedCards.swift
//  animation
//
//  ⚠️  REUSABLE GENERIC, NOT A STANDALONE DEMO. Consumed by
//      `View/ScrollView/StackedScrollView.swift:26` as the
//      Apple-Notifications-Center stacked card layout. Don't
//      rename or remove without updating that call site.
//
//  Learning point
//  ──────────────
//  Apple-style "stacked notifications" scroll: cards stack tightly
//  at the top of a scroll view, and as the user scrolls each card
//  scales DOWN, fades OUT, and offsets UP, sliding behind the next
//  one. Generic over `Data: RandomAccessCollection where
//  Data.Element: Identifiable`, so any Identifiable model works.
//
//  Three pure-math `visualEffect` callbacks
//  ────────────────────────────────────────
//  All driven from each card's `frame(in: .scrollView)` minY:
//    • `opacity(proxy)`  — 1.0 at "top of stack", fades to 0 as
//      scrolled past `stackedDisplayCount`-many cards.
//    • `scale(proxy)`    — 1.0 at top, shrinks to ~0.85 over the
//      same range, so cards look like they recede.
//    • `offset(proxy)`   — pulls each successive card UP toward
//      the previous one's anchor, creating the tight stack.
//
//  Reading these three together teaches the trick: pure functions
//  of scroll-space minY (no `@State`, no `onChange`), each returning
//  one transform value. SwiftUI calls them every frame; no manual
//  animation drives them. That's the elegant bit — the entire
//  stack effect is three functions, no state machine.
//
//  Why `nonisolated` on the helpers?
//  ─────────────────────────────────
//  The three helper functions are marked `nonisolated` so they
//  can be called from inside the `visualEffect` closure without
//  a MainActor hop. `visualEffect` runs during render-pass
//  (off-actor in newer SwiftUI), and the helpers don't touch any
//  actor-isolated state, so this is safe and avoids strict-
//  concurrency warnings.
//
//  Key APIs
//  ────────
//  • `.visualEffect { content, proxy in ... }` — runs per-frame
//    against the view-space frame; the load-bearing primitive.
//  • `proxy.frame(in: .scrollView(axis: .vertical)).minY` — the
//    scroll-space coordinate that drives all three transforms.
//  • `.scrollTargetBehavior(.viewAligned(limitBehavior: .alwaysByOne))`
//    — paged-snap-by-one so the stack resolves to a clean state.
//  • `.safeAreaPadding(.bottom, ...)` — leaves room for the last
//    card to scroll fully past the stack region.
//  • Generic `<Content: View, Data: RandomAccessCollection>` with
//    `Data.Element: Identifiable` — keeps the helper reusable.
//
//  How to apply
//  ────────────
//  Drop into any "feed of recent items" UI where the user should
//  feel the cards STACKING rather than just listing — notification
//  centres, message inboxes, recent-activity widgets. Tune
//  `stackedDisplayCount` for how many cards stay visible at the
//  top before fading.
//
//  See also
//  ────────
//  • View/ScrollView/StackedScrollView.swift — the consumer.
//  • View/Carousel/LoopingStackCardsDemoView.swift — different
//    "stack" pattern using iOS 18 `Group(subviews:)` + drag-to-
//    advance instead of scroll-driven recede. Compare for which
//    interaction model matches your product.
//
import SwiftUI

struct StackedCards<Content: View, Data: RandomAccessCollection>: View where Data.Element: Identifiable {
    var items: Data
    var stackedDisplayCount: Int = 2
    ///  number of extra cards needed to
    /// get the opacity effect in addition to the main card
    var opacityDisplayCount: Int = 2
    var spacing: CGFloat = 5
    var itemHeight: CGFloat
    @ViewBuilder var content: (Data.Element) -> Content

    var body: some View {
        GeometryReader {
            let size = $0.size
            let topPadding: CGFloat = size.height - itemHeight

            ScrollView(.vertical) {
                VStack(spacing: spacing) {
                    ForEach(items) { item in
                        content(item)
                            .frame(height: itemHeight)
                            .visualEffect { content, geometryProxy in
                                content
                                    .opacity(opacity(geometryProxy))
                                    .scaleEffect(scale(geometryProxy), anchor: .bottom)
                                    .offset(y: offset(geometryProxy))
                            }
                            .zIndex(zIndex(item))
                    }
                }
                .scrollTargetLayout()
                .overlay(alignment: .top) {
                    headerView(topPadding)
                }
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
            .safeAreaPadding(.top, topPadding)
            /// add padding directly to scrollContent rather than scrollView
            /// (if using standard padding) and thus allowing to scroll the stack all the way up
        }
    }

    func zIndex(_ item: Data.Element) -> Double {
        if let index = items.firstIndex(where: { $0.id == item.id }) as? Int {
            return Double(items.count) - Double(index)
        }
        return 0
    }

    /// Offset & scaling values for each item to make it look like a stack
    nonisolated func offset(_ proxy: GeometryProxy) -> CGFloat {
        let minY = proxy.frame(in: .scrollView(axis: .vertical)).minY
        let progress = minY / itemHeight
        let maxOffset = CGFloat(stackedDisplayCount) * offsetForEachItem
        let offset = max(min(progress * offsetForEachItem, maxOffset), 0)

        return minY < 0 ? 0 : -minY + offset
    }

    nonisolated func scale(_ proxy: GeometryProxy) -> CGFloat {
        let minY = proxy.frame(in: .scrollView(axis: .vertical)).minY
        let progress = minY / itemHeight
        let maxScale = CGFloat(stackedDisplayCount) * scaleForEachItem
        let scale = max(min(progress * scaleForEachItem, maxScale), 0)

        return 1 - scale
    }

    nonisolated func opacity(_ proxy: GeometryProxy) -> CGFloat {
        let minY = proxy.frame(in: .scrollView(axis: .vertical)).minY
        let progress = minY / itemHeight
        let opacityForItem = 1 / CGFloat(opacityDisplayCount + 1)

        let maxOpacity = CGFloat(opacityForItem) * CGFloat(opacityDisplayCount + 1)
        let opacity = max(min(progress * opacityForItem, maxOpacity), 0)

        return progress < CGFloat(opacityDisplayCount + 1) ? 1 - opacity : 0
    }

    nonisolated var offsetForEachItem: CGFloat {
        8
    }

    nonisolated var scaleForEachItem: CGFloat {
        0.08
    }

    func headerView(_ topPadding: CGFloat) -> some View {
        VStack(spacing: 0) {
            Text(Date.now.formatted(date: .complete, time: .omitted))
                .font(.title3.bold())

            Text("1:11")
                .font(.system(size: 100, weight: .bold, design: .rounded))
                .padding(.top, -15)
        }
        .foregroundStyle(.white)
        .visualEffect { content, geometryProxy in
            content.offset(y: headerViewOffset(geometryProxy, topPadding))
        }
    }

    /// position header view on top until stacked card getting close to it then scroll with the cards
    nonisolated func headerViewOffset(_ proxy: GeometryProxy, _ topPadding: CGFloat) -> CGFloat {
        let minY = proxy.frame(in: .scrollView(axis: .vertical)).minY
        let viewSize = proxy.size.height - itemHeight

        return -minY > (topPadding - viewSize) ? -viewSize : -minY - topPadding
    }
}

#Preview {
    StackedScrollView()
        .preferredColorScheme(.dark)
}
