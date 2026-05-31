//
//  InfiniteCarousel.swift
//  animation
//
//  ⚠️  WIRED INTO THE APP: `InfiniteCarouselIOS18DemoView` is referenced
//      from `View/CustomMenu/VisionProMenuBarView.swift:44` — don't
//      rename or delete without updating that demo.
//
//  iOS 18+ only — the gating API is `Group(subviews:)`.
//
//  Learning point
//  ──────────────
//  Auto-scrolling infinite carousel via the iOS 18 SubViews API.
//  Trick: duplicate the FIRST item at the END and the LAST item at
//  the FRONT, then on scroll-settle silently jump the scroll offset
//  back to the "real" position so the user never sees the seam.
//  Wired together with a `Timer` that nudges scroll forward every
//  N seconds for the auto-advance.
//
//  Loop sequence:
//    [last, item0, item1, …, itemN, first]
//             ↑                       ↑
//        if user lands on `first` → jump to itemN (no animation)
//        if user lands on `last`  → jump to item0 (no animation)
//
//  The settle detection is `onScrollPhaseChange` — only run the
//  jump when phase becomes `.idle`, otherwise we'd interrupt a
//  user gesture.
//
//  Also bundled in this file: `MenuBatControls` — the menu-bar
//  overlay that wraps the carousel for the VisionPro demo. The two
//  views share state so the carousel can pause auto-scroll while
//  the menu is expanded.
//
//  Key APIs
//  ────────
//  • `Group(subviews: content) { collection in ... }` — iOS 18+.
//    Lets us count items and synthesise the head/tail duplicates
//    without forcing the caller to use IDs.
//  • `Timer.scheduledTimer` + `withAnimation` + `scrollTo(id:)` for
//    auto-advance.
//  • `.onScrollPhaseChange` — settle detection.
//  • `.onScrollGeometryChange` — current page tracking for the
//    pager dots and the silent rebound.
//
//  How to apply
//  ────────────
//  Use whenever a carousel needs to wrap seamlessly (hero banners,
//  onboarding loops). Watch out: the head/tail duplicates double
//  the cost of the first/last cells — keep them cheap (image only,
//  no expensive children).
//
//  See also
//  ────────
//  • InfiniteLoopingScrollView.swift — alternate looping technique
//    that intercepts `UIScrollView` delegation for content offset
//    reset (no head/tail duplication, but UIKit-flavoured).
//  • View/CustomMenu/VisionProMenuBarView.swift — the consumer.
//
import SwiftUI

struct InfiniteCarouselIOS18DemoView: View {
    @State private var activePage: Int = 0
    @State private var items: [CreditCard] = creditCards
    /// View properties for menu bar
    @State private var isExpanded: Bool = false
    @State private var menuPosition: CGRect = .zero
    @Environment(\.colorScheme) private var colorScheme
    var body: some View {
        NavigationStack {
            VStack {
                headerView()

                InfiniteCarousel(activeIndex: $activePage) {
                    ForEach(items) { item in
                        RoundedRectangle(cornerRadius: 15)
                            .fill(item.color.gradient)
                            .padding(.horizontal, 15)
                    }
                }
                .frame(height: 220)

                /// Custom Indicators
                HStack(spacing: 5) {
                    ForEach(items.indices, id: \.self) { index in
                        Circle()
                            .fill(activePage == index ? .primary : .secondary)
                            .frame(width: 8, height: 8)
                    }
                }
                .animation(.snappy, value: activePage)
            }
            .navigationTitle("iOS18 Auto Scroll View")
            .overlay(alignment: .topLeading) {
                ZStack(alignment: .topLeading) {
                    Rectangle()
                        .foregroundStyle(.clear)
                        .contentShape(.rect)
                        .onTapGesture {
                            withAnimation(.snappy(duration: 0.3, extraBounce: 0)) {
                                isExpanded = false
                            }
                        }
                        .allowsHitTesting(isExpanded)

                    ZStack {
                        if isExpanded {
                            VisionProMenuBarView {
                                MenuBatControls()
                            }
                            .frame(width: 220, height: 270)
                            .transition(.blurReplace)
                        }
                    }
                }
                .offset(x: menuPosition.minX - 220 + menuPosition.width,
                        y: menuPosition.maxY - 270)
                .ignoresSafeArea()
            }
        }
    }

    func headerView() -> some View {
        HStack {
            Text("Notes")
                .font(.largeTitle.bold())

            Spacer(minLength: 0)

            /// Menu Button
            Button {
                withAnimation(.smooth) {
                    isExpanded.toggle()
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.title3)
                    .foregroundStyle(isExpanded ? colorScheme.currentColor : Color.primary)
                    .frame(width: 45, height: 45)
                    .background {
                        ZStack {
                            Rectangle()
                                .fill(.ultraThinMaterial)

                            Rectangle()
                                .fill(Color.primary.opacity(isExpanded ? 1 : 0.03))
                        }
                        .clipShape(.circle)
                    }
            }
            .onGeometryChange(for: CGRect.self) {
                $0.frame(in: .global)
            } action: { newValue in
                menuPosition = newValue
            }
        }
        .padding(15)
    }
}

struct InfiniteCarousel<Content: View>: View {
    @Binding var activeIndex: Int
    @ViewBuilder var content: Content
    /// View Properties
    @State private var offsetBasePosition: Int = 0
    @State private var isSettled: Bool = false
    @State private var scrollPosition: Int?
    @State private var isScrolling: Bool = false
    @GestureState private var isHoldingScreen: Bool = false
    @State private var timer = Timer.publish(every: autoScrollDuration, on: .main, in: .default).autoconnect()
    static var autoScrollDuration: CGFloat { 1.8 }

    var body: some View {
        GeometryReader {
            let size = $0.size

            Group(subviews: content) { collection in
                ScrollView(.horizontal) {
                    /// cannot use lazy stack for infinite effect due to view get recycles and not able to auto-scroll
                    HStack(spacing: 0) {
                        if let lastItem = collection.last { /// replace  the last item to the first position
                            lastItem
                                .frame(width: size.width, height: size.height)
                                .id(-1)
                        }

                        ForEach(collection.indices, id: \.self) { index in
                            collection[index]
                                .frame(width: size.width, height: size.height)
                                .id(index)
                        }

                        if let firstItem = collection.first {
                            firstItem
                                .frame(width: size.width, height: size.height)
                                .id(collection.count)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollPosition(id: $scrollPosition)
                .scrollTargetBehavior(.paging)
                .scrollIndicators(.hidden)
                .onScrollPhaseChange { _, newPhase in
                    isScrolling = newPhase.isScrolling

                    if !isScrolling, scrollPosition == -1 {
                        scrollPosition = collection.count - 1
                    }

                    if !isScrolling, scrollPosition == collection.count, !isHoldingScreen {
                        scrollPosition = 0
                    }
                }
                .simultaneousGesture( /// don't use in scrollView before  iOS18
                    DragGesture(minimumDistance: 0)
                        .updating($isHoldingScreen, body: { _, out, _ in
                            out = true
                        })
                )
                .onChange(of: isHoldingScreen) { _, newValue in
                    if newValue {
                        timer.upstream.connect().cancel()
                    } else {
                        if isSettled, scrollPosition != offsetBasePosition {
                            scrollPosition = offsetBasePosition
                        }
                        timer = Timer
                            .publish(every: Self.autoScrollDuration, on: .main, in: .default).autoconnect()
                    }
                }
                .onReceive(timer) { _ in
                    guard !isHoldingScreen, !isScrolling else { return }

                    let nextIndex = (scrollPosition ?? 0) + 1

                    withAnimation(.snappy(duration: 0.25, extraBounce: 0)) {
                        scrollPosition = (nextIndex == collection.count + 1) ? 0 : nextIndex
                    }
                }
                .onChange(of: scrollPosition) { _, newValue in
                    if let newValue {
                        /// activeIndex = max(min(newValue, collection.count - 1), 0) /// cause perceivable delay
                        if newValue == -1 {
                            activeIndex = collection.count - 1
                        } else if newValue == collection.count {
                            activeIndex = 0
                        } else {
                            activeIndex = max(min(newValue, collection.count - 1), 0)
                        }
                    }
                }
                /// reposition screen when view stops in between 2 cards
                .onScrollGeometryChange(for: CGFloat.self) {
                    $0.contentOffset.x
                } action: { _, newValue in
                    /// minus one card we insert at the front
                    isSettled = size.width > 0 ? (Int(newValue) % Int(size.width) == 0) : false
                    let index = size.width > 0 ? Int((newValue / size.width).rounded() - 1) : 0
                    offsetBasePosition = index

                    if isSettled, scrollPosition != index || index == collection.count, !isScrolling, !isHoldingScreen {
                        scrollPosition = index == collection.count ? 0 : index
                    }
                }
            }
            .onAppear { scrollPosition = 0 } /// so that card won't start with the last item
        }
    }
}

struct MenuBatControls: View {
    let controls = ["document.viewfinder", "pin.fill", "lock.fill"]
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 15) {
                ForEach(controls, id: \.self) { controlImage in
                    Button {} label: {
                        Image(systemName: controlImage)
                            .font(.title3)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                }
            }

            /// divider
            Rectangle()
                .fill(.black.opacity(0.1))
                .frame(height: 1)

            /// custom widgets
            customButton(title: "Search Note", image: "magnifyingglass")
            customButton(title: "Move Note", image: "folder")
            customButton(title: "Delete", image: "trash")
            customButton(title: "Format", image: "squareshape.split.3x3")
        }
        .padding(20)
    }

    private func customButton(title: String, image: String, action: @escaping () -> Void = {}) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 13))

                Spacer(minLength: 0)

                Image(systemName: image)
                    .frame(width: 20)
            }
            .frame(maxHeight: .infinity)
        }
    }
}

extension ColorScheme {
    var currentColor: Color {
        switch self {
        case .light:
            .white
        case .dark:
            .black
        default:
            .clear
        }
    }
}

#Preview {
    InfiniteCarouselIOS18DemoView()
}
