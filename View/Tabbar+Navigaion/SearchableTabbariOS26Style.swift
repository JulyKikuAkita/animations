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

            SearchableTabBariOS26Style(activeTab: $activeTab) { _ in

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
                    HStack(spacing: 0) {
                        ForEach(tabs, id: \.rawValue) { tab in
                            tabItemView(tab, width: tabItemWidth, height: tabItemHeight)
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
                        .frame(width: tabItemWidth, height: tabItemHeight)
                        /// Scaling when drag gesture becomes active
                        .scaleEffect(isActive ? 1.3 : 1)
                        .offset(x: dragOffset)
                    }
                    .padding(3)
                    .background(tabBarBackground())
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
        // TODO: custom animatons
        .animation(.bouncy, value: dragOffset)
        .animation(.bouncy, value: isActive)
        .animation(.smooth, value: activeTab)
    }

    func tabItemView(_ tab: VideoTab, width: CGFloat, height: CGFloat) -> some View {
        let tabs = VideoTab.allCases.prefix(showSearchBar ? 4 : 5)
        let tabCount = tabs.count - 1
        return VStack(spacing: 6) {
            Image(systemName: tab.symbol)
                .font(.title2)
                .symbolVariant(.fill)

            Text(tab.rawValue)
                .font(.caption2)
                .lineLimit(1)
        }
        .foregroundStyle(activeTab == tab ? accentColor : .primary)
        .frame(width: width, height: height)
        .contentShape(.capsule)
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
        .simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    activeTab = tab
                    dragOffset = CGFloat(tab.index) * width
                }
        )
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
    func modifiers(@ViewBuilder content: @escaping (Self) -> some View) -> some View {
        content(self)
    }
}

#Preview {
    SearchableTabbariOS26StyleDemoView()
}
