//
//  SearchableTabbariOS26Style.swift
//  animation
// Recreate iOS26 tab bar without glass effect and compatible with iOS16.4+

import SwiftUI

@main
struct SearchableTabbariOS26StyleDemo: App {
    var body: some Scene {
        WindowGroup {
            SearchableTabbariOS26StyleDemoView()
        }
    }
}

struct SearchableTabbariOS26StyleDemoView: View {
    @State private var activeTab: VideoTab = .home
    var body: some View {
        ZStack(alignment: .bottom) {
            Rectangle()
                .foregroundStyle(.clear)

            SearchableTabBariOS26Style(showSearchBar: true, activeTab: $activeTab) { _ in

            } onSearchTextChanged: { _ in
            }
        }
    }
}

struct SearchableTabBariOS26Style: View {
    /// View Properties
    var showSearchBar: Bool = false
    @Binding var activeTab: VideoTab
    var onSearchBarExpanded: (Bool) -> Void
    var onSearchTextChanged: (String) -> Void
    /// Drag Properties
    @GestureState private var isActive: Bool = false
    @State private var isInitialOffsetSet: Bool = false
    @State private var dragOffset: CGFloat = 0
    @State private var lastDragOffset: CGFloat?

    /// Search bar properties
    @State private var isSearchExpanded: Bool = false
    @State private var searchText: String = ""
    @FocusState private var isKeyboardActive: Bool

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            // setup max tabs based on search bar
            let tabs = VideoTab.allCases.prefix(showSearchBar ? 4 : 5)
            // setup range of tab width between [60, 90] based on search bar presence
            let tabItemWidth = max(min(size.width / CGFloat(tabs.count + (showSearchBar ? 1 : 0)), 90), 60)
            let tabItemHeight: CGFloat = 56

            ZStack {
                if isInitialOffsetSet {
                    let mainLayout = isKeyboardActive ? AnyLayout(ZStackLayout(alignment: .leading)) : AnyLayout(
                        HStackLayout(spacing: 12)
                    )
                    mainLayout {
                        /// Use AnyLayout for search expandable view
                        /// do not use if else
                        let tabLayout = isSearchExpanded ? AnyLayout(ZStackLayout()) : AnyLayout(HStackLayout(spacing: 0))
                        tabLayout {
                            ForEach(tabs, id: \.rawValue) { tab in
                                tabItemView(tab,
                                            width: isSearchExpanded ? 45 : tabItemWidth,
                                            height: isSearchExpanded ? 45 : tabItemHeight)
                                    .opacity(isSearchExpanded ? (activeTab == tab ? 1 : 0) : 1)
                            }
                        }
                        /// draggable active tab
                        .background(alignment: .leading) {
                            ZStack {
                                Capsule(style: .continuous)
                                    .stroke(.gray.opacity(0.25), lineWidth: 3)
                                    .opacity(isActive ? 1 : 0)

                                Capsule(style: .continuous)
                                    .fill(.background)
                            }
                            .compositingGroup()
                            .frame(width: tabItemWidth,
                                   height: tabItemHeight)
                            /// Scaling when drag gesture becomes active
                            .scaleEffect(isActive ? 1.3 : 1)
                            .offset(x: isSearchExpanded ? 0 : dragOffset)
                            .opacity(isSearchExpanded ? 0 : 1)
                        }
                        .padding(3)
                        .background(tabBarBackground())
                        .overlay {
                            if isSearchExpanded {
                                Capsule()
                                    .foregroundStyle(.clear)
                                    .contentShape(.capsule)
                                    .onTapGesture {
                                        withAnimation(.bouncy) {
                                            isSearchExpanded = false
                                        }
                                    }
                            }
                        }
                        /// hiding the tab icon when keyboard active
                        .opacity(isKeyboardActive ? 0 : 1)

                        if showSearchBar {
                            expandableSearchBar(height: isSearchExpanded ? 45 : tabItemHeight)
                        }
                    }
                    .optionalGeometryGroup()
                }
            }
            /// center tab bar
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .onAppear {
                guard !isInitialOffsetSet else { return }
                dragOffset = CGFloat(activeTab.index) * tabItemWidth
                isInitialOffsetSet = true
            }
        }
        .frame(height: 56)
        .padding(.horizontal, 25)
        .padding(.bottom, isKeyboardActive ? 10 : 0)
        // TODO: custom animatons
        .animation(.bouncy, value: dragOffset)
        .animation(.bouncy, value: isActive)
        .animation(.smooth, value: activeTab)
        .animation(.easeInOut(duration: 0.25), value: isKeyboardActive)
        .customOnChange(value: isKeyboardActive) {
            onSearchBarExpanded($0)
        }
        .customOnChange(value: searchText) {
            onSearchTextChanged($0)
        }
    }

    func tabItemView(_ tab: VideoTab, width: CGFloat, height: CGFloat) -> some View {
        let tabs = VideoTab.allCases.prefix(showSearchBar ? 4 : 5)
        let tabCount = tabs.count - 1
        return VStack(spacing: 6) {
            Image(systemName: tab.symbol)
                .font(.title2)
                .symbolVariant(.fill)

            if !isSearchExpanded {
                Text(tab.rawValue)
                    .font(.caption2)
                    .lineLimit(1)
            }
        }
        .foregroundStyle(activeTab == tab ? accentColor : .primary)
        .frame(width: width, height: height)
        .contentShape(.capsule)
        //  allow both tap and drag gestures to be recognized at the same time
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .updating($isActive, body: { _, out, _ in
                    out = true
                })
                .onChanged { value in
                    let xOffset = value.translation.width
                    if let lastDragOffset {
                        let newDragOffset = xOffset + lastDragOffset
                        dragOffset = max(min(newDragOffset, CGFloat(tabCount) * width), 0)
                    } else {
                        lastDragOffset = dragOffset
                    }
                }
                .onEnded { _ in
                    lastDragOffset = nil
                    /// identify the landing index
                    let landingIndex = Int((dragOffset / width).rounded())
                    /// double check the
                    if tabs.indices.contains(landingIndex) {
                        dragOffset = CGFloat(landingIndex) * width
                        activeTab = tabs[landingIndex]
                    }
                }
        )
        // allows instant selection of a tab with a tap
        .simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    activeTab = tab
                    dragOffset = CGFloat(tab.index) * width
                }
        )
        .optionalGeometryGroup() // support iOS 16.4+
    }

    private func expandableSearchBar(height: CGFloat) -> some View {
        let searchLayout = isKeyboardActive ? AnyLayout(HStackLayout(spacing: 12)) : AnyLayout(
            ZStackLayout(alignment: .trailing)
        )
        return searchLayout {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(isSearchExpanded ? .body : .title2)
                    .foregroundStyle(isSearchExpanded ? .gray : .primary)
                    .frame(width: isSearchExpanded ? nil : height, height: height)
                    .onTapGesture {
                        withAnimation(.bouncy) {
                            isSearchExpanded = true
                        }
                    }
                    .allowsHitTesting(!isSearchExpanded)

                if isSearchExpanded {
                    TextField("Search...", text: $searchText)
                        .focused($isKeyboardActive)
                }
            }
            .padding(.horizontal, isSearchExpanded ? 15 : 0)
            .background(tabBarBackground())
            .optionalGeometryGroup()
            .zIndex(1)

            /// toggle focus state
            Button {
                isKeyboardActive = false
                searchText = ""
            } label: {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundStyle(.primary)
                    .frame(width: height, height: height)
                    .background(tabBarBackground())
            }
            .opacity(isKeyboardActive ? 1 : 0)
        }
        .optionalGeometryGroup()
    }

    private func tabBarBackground() -> some View {
        ZStack {
            Capsule(style: .continuous)
                .stroke(.gray.opacity(0.25), lineWidth: 1.5)

            Capsule(style: .continuous)
                .fill(.background.opacity(0.8))

            Capsule(style: .continuous)
                .fill(.ultraThinMaterial)
        }
        .compositingGroup()
    }

    var accentColor: Color {
        .blue
    }
}

private extension View {
    @ViewBuilder
    func optionalGeometryGroup() -> some View {
        if #available(iOS 17, *) {
            self
                .geometryGroup()
        } else {
            self
        }
    }
}

#Preview {
    SearchableTabbariOS26StyleDemoView()
}
