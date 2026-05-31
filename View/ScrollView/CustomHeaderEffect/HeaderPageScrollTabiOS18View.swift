//
//  HeaderPageScrollTabiOS18View.swift
//  animation
//
//  Standalone demo (not wired into the app's demo browser; preview-only).
//  iOS 18+ — `Group(subviews:)`, multi-scroll `scrollPosition`
//  bindings, per-tab `onScrollPhaseChange`.
//
//  Inline notes (preserved from the original header):
//
// How iOS18 api helps synchronizing scrollView interactions:
// 1. using scrollPosition to sync scrollView offsets:
//  - when offset is < 0, (bouncing), reset all other scrollviews to initial position
//  - when is scrolling, update other scrollviews.
//      -- by checking after the tab bar reaches top
//
//  Learning point
//  ──────────────
//  Multi-tab paging layout where each tab has its OWN vertical
//  scroll, all sharing a STICKY HEADER + tab bar that hides as
//  any tab scrolls down. The tricky bit is keeping the per-tab
//  scroll positions IN SYNC so the header animation stays
//  consistent regardless of which tab the user is on — switching
//  tabs after scrolling tab A shouldn't reset the header.
//
//  Sync mechanics:
//    1. Each tab gets its own `@State scrollPosition` binding.
//    2. `onScrollPhaseChange` fires per-tab; the handler updates
//       a SHARED `@State` representing the global scroll state.
//    3. When the user switches tabs, the destination tab applies
//       the shared state to its scroll position via the binding.
//  This is the iOS-18-only path — pre-iOS-18 you'd reach for
//  `UIScrollViewDelegate` to coordinate, see
//  [[View/Carousel/InfiniteLoopingScrollView]] for an example of
//  that.
//
//  Key APIs
//  ────────
//  • `Group(subviews:)` (iOS 17.1+) — extracts page bodies so each
//    one can have its own scroll position binding.
//  • `.scrollPosition($scrollPositions[index])` — per-tab binding
//    in an array.
//  • `.onScrollPhaseChange` — per-tab settle detection that updates
//    the shared global scroll state.
//  • `.scrollClipDisabled()` — needed because the sticky header
//    extends above each tab's scroll frame.
//
//  How to apply
//  ────────────
//  Use for any tabbed UX where each tab has long content but the
//  CHROME (header, tab bar) should feel like one shared element
//  (Twitter profile, Apple Music, App Store). The shared-scroll-
//  state pattern is the reusable nugget.
//
//  See also
//  ────────
//  • View/ScrollView/CustomHeaderEffect/ResizableHeaderIOS26View.swift
//    — single-scroll header collapse using iOS 26 Liquid Glass.
//  • View/ScrollView/CustomHeaderEffect/ScrollToHideHeaderView.swift
//    — single-scroll hide-on-scroll header.
//
import SwiftUI

struct HeaderPageScrollTabiOS18DemoView: View {
    var body: some View {
        HeaderPageScrollTabiOS18View(displaysSymbols: false) {
            RoundedRectangle(cornerRadius: 25)
                .fill(.indigo.gradient)
                .frame(height: 350)
                .padding()
        } labels: {
            PageLabel(title: "Posts", symbolImage: "square.grid.3x3.fill")
            PageLabel(title: "Reels", symbolImage: "photo.stack.fill")
            PageLabel(title: "Tagged", symbolImage: "person.square.rectangle")
        } pages: {
            /// assuming each is individual tab view
            DummyRectangles(color: .green, count: 5)

            Text("Reels")
            DummyRectangles(color: .orange, count: 45)
        } onRefresh: {}
    }
}

struct PageLabel {
    var title: String
    var symbolImage: String
}

@resultBuilder
struct PageLabelBuilder {
    static func buildBlock(_ components: PageLabel...) -> [PageLabel] {
        components.compactMap(\.self)
    }
}

struct HeaderPageScrollTabiOS18View<Header: View, Pages: View>: View {
    var displaysSymbols: Bool = false
    var header: Header
    /// labels: tab title or tab images
    var labels: [PageLabel]
    var pages: Pages
    var onRefresh: () async -> Void

    init(
        displaysSymbols: Bool = false,
        @ViewBuilder header: @escaping () -> Header,
        @PageLabelBuilder labels: @escaping () -> [PageLabel],
        @ViewBuilder pages: @escaping () -> Pages,
        onRefresh: @escaping () async -> Void = {}
    ) {
        self.displaysSymbols = displaysSymbols
        self.header = header()
        self.labels = labels()
        self.pages = pages()
        self.onRefresh = onRefresh

        let count = labels().count
        _scrollPositions = .init(initialValue: .init(repeating: .init(), count: count))
        _scrollGeometries = .init(initialValue: .init(repeating: .init(), count: count))
    }

    /// View Properties
    @State private var activeTabText: String?
    @State private var headerHeight: CGFloat = 0
    @State private var scrollGeometries: [ScrollGeometry]
    @State private var scrollPositions: [ScrollPosition]

    /// Main Scroll Properties
    @State private var mainScrollDisabled: Bool = false
    @State private var mainScrollPhase: ScrollPhase = .idle
    @State private var mainScrollGeometry: ScrollGeometry = .init()

    /// Constants
    let headerFrameHeight: CGFloat = 40

    var body: some View {
        GeometryReader {
            let size = $0.size

            ScrollView(.horizontal) {
                /// using hstack allowing us to maintain reference to other scrollviews for future updates
                HStack(spacing: 0) {
                    Group(subviews: pages) { collection in
                        if collection.count != labels.count {
                            Text("Textviews and labels does not match")
                                .frame(width: size.width, height: size.height)
                        } else {
                            ForEach(labels, id: \.title) { label in
                                pageScrollView(label: label, size: size, collection: collection)
                            }
                        }
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $activeTabText)
            .scrollIndicators(.hidden)
            .scrollDisabled(mainScrollDisabled)
            /// disable interaction during animation
            .allowsHitTesting(mainScrollPhase == .idle)
            .onScrollPhaseChange { _, newPhase in
                mainScrollPhase = newPhase
            }
            .onScrollGeometryChange(for: ScrollGeometry.self, of: {
                $0
            }, action: { _, newValue in
                mainScrollGeometry = newValue
            })
            .mask {
                Rectangle()
                    .ignoresSafeArea(.all, edges: .bottom)
            }
            .onAppear {
                guard activeTabText == nil else { return }
                activeTabText = labels.first?.title
            }
        }
    }

    // swiftlint:disable:next function_body_length
    func pageScrollView(label: PageLabel, size: CGSize, collection: SubviewsCollection) -> some View {
        let index = labels.firstIndex(where: { $0.title == label.title }) ?? 0
        return ScrollView(.vertical) {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                /// show header view for the active tab only
                ZStack {
                    if activeTabText == label.title {
                        header
                            /// sticky header effect (combine w/ .scrollClipDisabled())
                            .visualEffect { content, proxy in
                                content
                                    .offset(x: -proxy.frame(in: .scrollView(axis: .horizontal)).minX)
                            }
                            .onGeometryChange(for: CGFloat.self) {
                                $0.size.height
                            } action: { newValue in
                                headerHeight = newValue
                            }
                            .transition(.identity)
                    } else {
                        Rectangle()
                            .foregroundStyle(.clear)
                            .frame(height: headerHeight)
                            .transition(.identity)
                    }
                }
                .simultaneousGesture(horizontalScrollDisableGesture)

                /// using pinned views to pin tab bar on the top
                Section {
                    collection[index]
                        /// always able to scroll up to hide header view
                        .frame(minHeight: size.height - headerFrameHeight, alignment: .top)
                } header: {
                    // same sticky effect as header view
                    ZStack {
                        if activeTabText == label.title {
                            customTabBar()
                                .visualEffect { content, proxy in
                                    content
                                        .offset(x: -proxy.frame(in: .scrollView(axis: .horizontal)).minX)
                                }
                                .transition(.identity)
                        } else {
                            Rectangle()
                                .foregroundStyle(.clear)
                                .frame(height: headerFrameHeight)
                                .transition(.identity)
                        }
                    }
                    .simultaneousGesture(horizontalScrollDisableGesture)
                }
            }
        }
        .onScrollGeometryChange(for: ScrollGeometry.self, of: {
            $0
        }, action: { _, newValue in
            scrollGeometries[index] = newValue
            if newValue.offsetY < 0 {
                resetScrollViews(label)
            }
        })
        .scrollPosition($scrollPositions[index])
        .onScrollPhaseChange { _, newPhase in
            let geometry = scrollGeometries[index]
            let maxOffset = min(geometry.offsetY, headerHeight)

            if newPhase == .idle, maxOffset <= headerHeight {
                updateOtherScrollViews(from: label, to: maxOffset)
            }

            /// fail-safe
            if newPhase == .idle, mainScrollDisabled {
                mainScrollDisabled = false
            }
        }
        .frame(width: size.width)
        .scrollClipDisabled()
        /// active tab should always be on top
        .zIndex(activeTabText == label.title ? 1000 : 0)
        .refreshable {
            await onRefresh()
        }
    }

    func customTabBar() -> some View {
        let progress = mainScrollGeometry.offsetX / mainScrollGeometry.containerSize.width
        return VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 0) {
                ForEach(labels, id: \.title) { label in
                    Group {
                        if displaysSymbols {
                            Image(systemName: label.symbolImage)
                        } else {
                            Text(label.title)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(activeTabText == label.title ? Color.primary : .gray)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            activeTabText = label.title
                        }
                    }
                }
            }

            /// sliding indicator for active tab
            Capsule()
                .frame(width: 50, height: 4)
                .containerRelativeFrame(.horizontal) { value, _ in
                    value / CGFloat(labels.count)
                }
                .visualEffect { content, proxy in
                    content
                        .offset(x: proxy.size.width * progress)
                }
        }
        .frame(height: headerFrameHeight)
        .background(.background)
    }

    func resetScrollViews(_ from: PageLabel) {
        for index in labels.indices where labels[index].title != from.title {
            scrollPositions[index].scrollTo(y: 0)
        }
    }

    func updateOtherScrollViews(from fromLabel: PageLabel, to toLabel: CGFloat) {
        for index in labels.indices {
            let label = labels[index]
            let offset = scrollGeometries[index].offsetY
            let wantsUpdate = offset < headerHeight || toLabel < headerHeight
            if wantsUpdate, label.title != fromLabel.title {
                scrollPositions[index].scrollTo(y: toLabel)
            }
        }
    }

    var horizontalScrollDisableGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                mainScrollDisabled = true
            }.onEnded { _ in
                mainScrollDisabled = false
            }
    }
}

#Preview {
    HeaderPageScrollTabiOS18DemoView()
}

private extension ScrollGeometry {
    init() {
        self.init(
            contentOffset: .zero,
            contentSize: .zero,
            contentInsets: .init(.zero),
            containerSize: .zero
        )
    }

    var offsetY: CGFloat {
        contentOffset.y + contentInsets.top
    }

    var offsetX: CGFloat {
        contentOffset.x + contentInsets.leading
    }
}
