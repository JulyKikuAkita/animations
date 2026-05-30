//
//  HorizontalTabView.swift
//  animation
//
//  Learning point
//  ──────────────
//  YouTube-style horizontal page swiper with a scrollable tab bar
//  above it. The tab bar and the content scroll view stay in lockstep
//  in BOTH directions:
//    • Tap a tab → animate the content scroll view to that page AND
//      center the tapped tab in the strip.
//    • Swipe the content → update the active tab AND auto-center it.
//  The bottom indicator (line under the active tab) is INTERPOLATED
//  off the live scroll progress so it slides smoothly during the
//  swipe, including width interpolation when adjacent tabs differ
//  in label length.
//
//  Key APIs
//  ────────
//  • `.scrollPosition(id:)` — iOS 17. Bound to the active page id;
//    write to it programmatically to scroll, read it as user swipes.
//  • `.scrollTargetLayout()` + `.scrollTargetBehavior(.paging)` — page
//    snap behavior on the LazyHStack.
//  • `OffsetKey` (project helper) + `.rect(completion:)` extension —
//    captures each tab's `frame(in: .scrollView(axis: .horizontal))`
//    via PreferenceKey. Real-time even when the indicator is rendered
//    OUTSIDE the scroll view.
//  • `progress.interpolate(inputRange:outputRange:)` — project helper
//    for piecewise-linear interpolation; drives indicator width AND
//    horizontal offset off the same `progress` scalar.
//
//  How to apply
//  ────────────
//  Use when content lives in a horizontal pager (Twitter timelines,
//  YouTube feed sections). The two-way sync is the value — most
//  homemade tab strips only sync ONE direction and feel broken on
//  swipe.
//
//  See also
//  ────────
//  • ScrollablePageTabsColorView.swift — older `tabViewStyle(.page)`
//    approach that bridges to UICollectionView via KVO for the same
//    progress signal. Use HorizontalTabView for new code.
//

import SwiftUI

struct HorizontalTabView: View {
    /// View properties
    @State private var tabs: [TabModel] = [
        .init(id: TabModel.HorizonTab.research, idInt: 0),
        .init(id: TabModel.HorizonTab.development, idInt: 2),
        .init(id: TabModel.HorizonTab.analytics, idInt: 3),
        .init(id: TabModel.HorizonTab.audience, idInt: 4),
        .init(id: TabModel.HorizonTab.privacy, idInt: 5),
    ]
    @State private var activeTab: TabModel.HorizonTab = .research
    @State private var mainViewScrollState: TabModel.HorizonTab? // scroll to view matched tab bar
    @State private var tabBarScrollState: TabModel.HorizonTab? // center selected tab
    @State private var progress: CGFloat = .zero

    var body: some View {
        VStack(spacing: 0) {
            headerView()
            customTabBar()

            /// main view
            GeometryReader {
                let size = $0.size

                ScrollView(.horizontal) { // require each tab view to be full screen width
                    LazyHStack(spacing: 0) {
                        /// individual tab view
                        ForEach(tabs) { tab in
                            Text(tab.id.rawValue)
                                .frame(width: size.width, height: size.height)
                                .contentShape(.rect)
                        }
                    }
                    .scrollTargetLayout()
                    .rect { rect in
                        progress = -rect.minX / size.width
                    }
                }
                // data type needs to match foreach loop data (HorizonTab in this case)
                .scrollPosition(id: $mainViewScrollState)
                .scrollIndicators(.hidden)
                .scrollTargetBehavior(.paging)
                // sync tab bar when swipe view
                .onChange(of: mainViewScrollState) { _, newValue in
                    if let newValue {
                        withAnimation(.snappy) {
                            tabBarScrollState = newValue
                            activeTab = newValue
                        }
                    }
                }
            }
        }
    }

    /// Header view
    func headerView() -> some View {
        HStack {
            Image(.fox) // youtube logo
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100)

            Spacer(minLength: 0)

            /// Buttons
            Button("", systemImage: "plus.circle") {}
                .font(.title2)
                .tint(.primary)

            Button("", systemImage: "bell") {}
                .font(.title2)
                .tint(.primary)

            Button(action: {}, label: {
                Image(.fox)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 30, height: 30)
                    .clipShape(.circle)
            })
        }
        .padding(15)
    }

    /// Dynamic scrollable tab bar
    func customTabBar() -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: 20) {
                ForEach($tabs) { $tab in
                    Button {
                        withAnimation(.snappy) {
                            activeTab = tab.id
                            mainViewScrollState = tab.id
                            tabBarScrollState = tab.id
                        }
                    } label: {
                        Text(tab.id.rawValue)
                            .padding(.vertical, 12)
                            .foregroundStyle(activeTab == tab.id ? Color.primary : .gray)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    // update minX so even when placed the indicator outside the scrollview
                    // scroll indicator also get real time updates
                    .rect { rect in
                        tab.size = rect.size
                        tab.minX = rect.minX
                    }
                }
            }
            .scrollTargetLayout()
        }
        .scrollPosition(id: .init(get: {
            tabBarScrollState
        }, set: { _ in
            // we only need get
        }), anchor: .center)
        .overlay(alignment: .bottom) { // tab bar indicator
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(.gray.opacity(0.3))
                    .frame(height: 1)

                // dynamically set indicator width
                let inputRange = tabs.indices.compactMap { CGFloat($0) }
                let outputRange = tabs.compactMap(\.size.width)
                let outputPositionRange = tabs.compactMap(\.minX)

                let indicatorWidth = progress.interpolate(inputRange: inputRange, outputRange: outputRange)
                let indicatorPosition = progress.interpolate(inputRange: inputRange, outputRange: outputPositionRange)

                Rectangle()
                    .fill(.primary)
                    .frame(width: indicatorWidth, height: 1.5)
                    .offset(x: indicatorPosition)
            }
        }
        .safeAreaPadding(.horizontal, 15)
        .scrollIndicators(.hidden)
    }
}

/// Use OffsetKey to calculate the width of each tab
///  to position tab indicator properly
extension View {
    @ViewBuilder
    func rect(completion: @escaping (CGRect) -> Void) -> some View {
        overlay {
            GeometryReader {
                let rect = $0.frame(in: .scrollView(axis: .horizontal))

                Color.clear
                    .preference(key: OffsetKey.self, value: rect)
                    .onPreferenceChange(OffsetKey.self, perform: completion)
            }
        }
    }
}

#Preview {
    HorizontalTabView()
}
