//
//  InfiniteLoopingScrollView.swift
//  animation
//
//  Standalone demo (not wired into the app's demo browser; preview-only).
//  Source: https://www.youtube.com/watch?v=lyuo59840qs (index 56).
//
//  TODO: Cleanup candidates
//        1. The `asyncAfter(deadline: .now() + 0.06)` inside
//           `ScrollViewHelper` is timing-fragile — it waits "long
//           enough" for SwiftUI to install the underlying UIScrollView
//           into the view hierarchy. Investigate
//           `UIIntrospect`-style introspection or
//           `UIViewRepresentable`'s newer `Coordinator` lifecycle to
//           replace the magic delay.
//        2. The `superview?.superview?.superview` chain to find the
//           UIScrollView is a private-implementation-detail trap —
//           any SwiftUI internal change can break it.
//        3. Compare with [[InfiniteCarouselView]] — same goal, two
//           very different techniques. If both stay, document why we
//           keep both; if not, drop one.
//
//  Learning point
//  ──────────────
//  Alternative "infinite scroll" technique: instead of duplicating
//  head/tail items in SwiftUI (see [[InfiniteCarouselView]]), reach
//  through SwiftUI to grab the underlying `UIScrollView` and
//  intercept `scrollViewDidScroll` to RESET the contentOffset whenever
//  the user nears either end. The user never sees the seam because
//  the reset is one-frame instant.
//
//  Trade-offs vs the SubViews-duplication technique:
//    • + Doesn't duplicate cells (cheaper for expensive content).
//    • + Smooth at any scroll velocity.
//    • − Requires walking SwiftUI's view tree (`superview` chain) to
//        find the actual UIScrollView — fragile.
//    • − Needs `asyncAfter` to wait for view-tree installation.
//
//  Key APIs
//  ────────
//  • `UIViewRepresentable` + `Coordinator: UIScrollViewDelegate` —
//    the bridge to UIKit's delegate methods.
//  • `scrollViewDidScroll(_:)` — fires every frame; reset offset
//    when contentOffset.x < itemWidth or ≥ N×itemWidth.
//  • Generic `LoopingScrollView<Content, Item>` — repeats the source
//    items enough times to fill the scroll runway, then snaps back.
//
//  How to apply
//  ────────────
//  Use when the cells are too heavy to duplicate (large images,
//  video thumbnails). Otherwise prefer
//  [[InfiniteCarouselView]] — pure SwiftUI, no UIKit reach-through.
//
//  See also
//  ────────
//  • InfiniteCarouselView.swift — pure-SwiftUI alternative using
//    head/tail duplicates.
//
import SwiftUI

struct InfiniteLoopingScrollDemoView: View {
    var body: some View {
        NavigationStack {
            InfiniteLoopingScrollView()
                .navigationTitle("Looping Scroll View")
        }
    }
}

struct InfiniteLoopingScrollView: View {
    @State private var items: [CreditCard] = creditCards
    var body: some View {
        ScrollView(.vertical) {
            VStack {
                GeometryReader {
                    let size = $0.size
                    LoopingScrollView(width: size.width, spacing: 0, items: items) { item in
                        let index = items.firstIndex(where: { $0.id == item.id }) ?? -100
                        RoundedRectangle(cornerRadius: 15)
                            .fill(item.color.gradient)
                            .padding(.horizontal, 15)
                            .overlay {
                                Text("\(index + 1)")
                                    .font(.largeTitle)
                                    .foregroundStyle(.gray)
                            }
                    }
                    /// adding margin to scrollview w/o impacting it's natural bound
//                    .contentMargins(.horizontal, 15, for: .scrollContent)
                    .scrollTargetBehavior(.paging)
                }
                .frame(height: 220)
            }
            .padding(.vertical, 15)
        }
        .scrollIndicators(.hidden)
    }
}

/// iOS 17: passing data as  a randomly accessible collection
struct LoopingScrollView<Content: View, Item: RandomAccessCollection>: View where Item.Element: Identifiable {
    /// Custom Properties
    var width: CGFloat
    var spacing: CGFloat = 0
    var items: Item
    @ViewBuilder var content: (Item.Element) -> Content
    var body: some View {
        GeometryReader {
            let size = $0.size
            let repeatingCount = width > 0 ? Int((size.width / width).rounded()) + 1 : 1 // should not == 0

            ScrollView(.horizontal) {
                LazyHStack(spacing: spacing) {
                    ForEach(items) { item in
                        content(item)
                            .frame(width: width)
                    }

                    ForEach(0 ..< repeatingCount, id: \.self) { index in
                        let item = Array(items)[index % items.count]
                        content(item)
                            .frame(width: width)
                    }
                }
                .background {
                    ScrollViewHelper(
                        width: width,
                        spacing: spacing,
                        itemsCount: items.count,
                        repeatingCount: repeatingCount
                    )
                }
            }
        }
    }
}

private struct ScrollViewHelper: UIViewRepresentable {
    var width: CGFloat
    var spacing: CGFloat
    var itemsCount: Int
    var repeatingCount: Int

    func makeCoordinator() -> Coordinator {
        Coordinator(
            width: width,
            spacing: spacing,
            itemsCount: itemsCount,
            repeatingCount: repeatingCount
        )
    }

    func makeUIView(context _: Context) -> UIView {
        .init()
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            if let scrollView = uiView.superview?.superview?.superview as? UIScrollView, !context.coordinator.isAdded {
                scrollView.delegate = context.coordinator
                context.coordinator.isAdded = true
            }
        }
        context.coordinator.width = width
        context.coordinator.spacing = spacing
        context.coordinator.itemsCount = itemsCount
        context.coordinator.repeatingCount = repeatingCount
    }

    class Coordinator: NSObject, UIScrollViewDelegate {
        var width: CGFloat
        var spacing: CGFloat
        var itemsCount: Int
        var repeatingCount: Int

        init(
            width: CGFloat,
            spacing: CGFloat,
            itemsCount: Int,
            repeatingCount: Int
        ) {
            self.width = width
            self.spacing = spacing
            self.itemsCount = itemsCount
            self.repeatingCount = repeatingCount
        }

        /// whether the delegate is added or not
        var isAdded: Bool = false

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            guard itemsCount > 0 else { return }
            let minX = scrollView.contentOffset.x
            let mainContentSize = CGFloat(itemsCount) * width
            let spacingSize = CGFloat(itemsCount) * spacing

            if minX > (mainContentSize + spacingSize) {
                scrollView.contentOffset.x -= (mainContentSize + spacingSize)
            }

            if minX < 0 {
                scrollView.contentOffset.x += (mainContentSize + spacingSize)
            }
        }
    }
}

#Preview {
    InfiniteLoopingScrollDemoView()
}
