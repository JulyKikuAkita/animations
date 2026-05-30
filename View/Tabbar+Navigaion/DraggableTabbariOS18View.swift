//
//  DraggableTabbariOS18View.swift
//  animation
//
//  Learning point
//  ──────────────
//  Drag-to-SELECT (not reorder): the user drags across the tab bar
//  and the active tab follows the finger, snapping to whichever tab
//  the finger is currently over. Two visual treatments live in this
//  one file:
//    1. `FloatingInteractiveTabBar` — capsule pill with `matchedGeometryEffect`
//       sliding under the dragged-over tab.
//    2. `DraggableTabBariOS18` — circular icon that scales up and an
//       elevated padding effect on the active tab (Dock-style bounce).
//
//  Hit-detection trick: each tab records its `frame(in: .named("TABBAR"))`
//  via `.onGeometryChange`. The drag gesture lives in the same named
//  coordinate space, so deciding which tab is under the finger is just
//  `tabButtonsLocations.firstIndex(where: { $0.contains(value.location) })`.
//
//  Key APIs
//  ────────
//  • `DragGesture(coordinateSpace: .named("TABBAR"))` + `coordinateSpace(.named(...))`
//  • `.onGeometryChange(for: CGRect.self, of: .frame(in: .named(...)))` —
//    rect-per-tab capture, the heart of hit-testing.
//  • `matchedGeometryEffect(id: "ACTIVETAB", in: animation)` — the
//    sliding pill / circle.
//  • `gesture(_, isEnabled: activeTab == tab)` — only the active tab
//    owns the drag gesture; non-active tabs receive taps. The inline
//    comment notes why `isActive` would be wrong here (it would
//    disable mid-drag).
//
//  How to apply
//  ────────────
//  Use when tabs themselves should be draggable input (camera mode
//  pickers, iOS Camera shutter, "swipe-style" tab strips). For
//  REORDERING tabs, see DraggableTabbarView.swift instead.
//
//  See also
//  ────────
//  • DraggableTabbarView.swift — drag-to-REORDER variant (edit mode,
//    persistence, haptics). Different gesture, different goal.
//  • iOS26/iOS26SegmentedTabBar.swift — the iOS 26 evolution of the
//    drag-to-select pattern with glass + scroll-snap.
//

import SwiftUI

struct DraggableTabBariOS18DemoView: View {
    @State private var activeTab: TabiOS17 = .apps
    var body: some View {
        ZStack(alignment: .bottom) {
            if #available(iOS 18, *) {
                TabView(selection: $activeTab) {
                    ForEach(TabiOS17.allCases, id: \.rawValue) { tab in
                        Tab(value: tab) {
                            // must hide the native tab bar
                            Text(tab.title)
                                .toolbarVisibility(.hidden, for: .tabBar)
                        }
                    }
                }
            } else {
                TabView(selection: $activeTab) {
                    ForEach(TabiOS17.allCases, id: \.rawValue) { tab in
                        Text(tab.title)
                            .tag(tab)
                            // must hide the native tab bar
                            .toolbar(.hidden, for: .tabBar)
                    }
                }
            }
        }

        FloatingInteractiveTabBar(activeTab: $activeTab)

        DraggableTabBariOS18(activeTab: $activeTab)
    }
}

struct FloatingInteractiveTabBar: View {
    @Binding var activeTab: TabiOS17
    /// View Properties
    @Namespace private var animation
    /// storing the locations of the tab buttons to identify the currently dragging tab
    @State private var tabButtonsLocations: [CGRect] = Array(repeating: .zero, count: TabiOS17.allCases.count)
    /// using this property to animate the changes in the tab bar itself but not the whole tab bar view
    @State private var activeDraggingTab: TabiOS17?
    var body: some View {
        HStack(spacing: 0) {
            ForEach(TabiOS17.allCases, id: \.rawValue) { tab in
                tabButton(tab)
            }
        }
        .frame(height: 40)
        .background {
            Capsule()
                .fill(.background.shadow(.drop(color: .primary.opacity(0.2), radius: 5)))
        }
        .coordinateSpace(.named("TABBAR"))
        .padding(.horizontal, 15)
        .padding(.bottom, 10)
    }

    func tabButton(_ tab: TabiOS17) -> some View {
        let isActive = (activeDraggingTab ?? activeTab) == tab

        return VStack(spacing: 6) {
            Image(systemName: tab.rawValue)
                .symbolVariant(.fill)
                .foregroundStyle(isActive ? .white : .primary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            if isActive {
                Capsule()
                    .fill(.blue.gradient)
                    .matchedGeometryEffect(id: "ACTIVETAB", in: animation)
            }
        }
        .contentShape(.rect) /// check the icon size has been cropped or not
        .onGeometryChange(for: CGRect.self, of: {
            $0.frame(in: .named("TABBAR"))
        }, action: { newValue in
            tabButtonsLocations[tab.index] = newValue
        })
        .onTapGesture {
            withAnimation(.snappy) {
                activeTab = tab
            }
        }
        .gesture(
            DragGesture(coordinateSpace: .named("TABBAR"))
                .onChanged { value in
                    let location = value.location
                    /// map location to the proper tab index
                    if let index = tabButtonsLocations.firstIndex(where: { $0.contains(location) }) {
                        withAnimation(.snappy(duration: 0.25, extraBounce: 0)) {
                            activeDraggingTab = TabiOS17.allCases[index]
                        }
                    }
                }.onEnded { _ in
                    if let activeDraggingTab {
                        activeTab = activeDraggingTab
                    }
                    activeDraggingTab = nil
                },
            /// do not use isActive  ->
            /// as it will immediate disabled when tab is moved as it checks drag value
            isEnabled: activeTab == tab
        )
    }
}

struct DraggableTabBariOS18: View {
    @Binding var activeTab: TabiOS17
    /// View Properties
    @Namespace private var animation
    /// storing the locations of the tab buttons to identify the currently dragging tab
    @State private var tabButtonsLocations: [CGRect] = Array(repeating: .zero, count: TabiOS17.allCases.count)
    /// using this property to animate the changes in the tab bar itself but not the whole tab bar view
    @State private var activeDraggingTab: TabiOS17?
    var body: some View {
        HStack(spacing: 0) {
            ForEach(TabiOS17.allCases, id: \.rawValue) { tab in
                tabButton(tab)
            }
        }
        .frame(height: 70)
        .padding(.horizontal, 15)
        .padding(.bottom, 10)
        .background {
            Rectangle()
                .fill(.background.shadow(.drop(color: .primary.opacity(0.2), radius: 5)))
                .ignoresSafeArea()
                .padding(.top, 20)
        }
        .coordinateSpace(.named("TABBAR"))
    }

    func tabButton(_ tab: TabiOS17) -> some View {
        let isActive = (activeDraggingTab ?? activeTab) == tab

        return VStack(spacing: 6) {
            Image(systemName: tab.rawValue)
                .symbolVariant(.fill)
                .frame(width: isActive ? 50 : 25, height: isActive ? 50 : 25)
                .background {
                    if isActive {
                        Circle()
                            .fill(.blue.gradient)
                            .matchedGeometryEffect(id: "ACTIVETAB", in: animation)
                    }
                }
                /// create an elevation effect when push the active tab
                .frame(width: 25, height: 25, alignment: .bottom)
                .foregroundStyle(isActive ? .white : .primary)

            Text(tab.title)
                .font(.caption2)
                .foregroundStyle(isActive ? .blue : .gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .contentShape(.rect) /// check the icon size has been cropped or not
        .padding(isActive ? 10 : 0)
        .onGeometryChange(for: CGRect.self, of: {
            $0.frame(in: .named("TABBAR"))
        }, action: { newValue in
            tabButtonsLocations[tab.index] = newValue
        })
        .onTapGesture {
            withAnimation(.snappy) {
                activeTab = tab
            }
        }
        .gesture(
            DragGesture(coordinateSpace: .named("TABBAR"))
                .onChanged { value in
                    let location = value.location
                    /// map location to the proper tab index
                    if let index = tabButtonsLocations.firstIndex(where: { $0.contains(location) }) {
                        withAnimation(.snappy(duration: 0.25, extraBounce: 0)) {
                            activeDraggingTab = TabiOS17.allCases[index]
                        }
                    }
                }.onEnded { _ in
                    if let activeDraggingTab {
                        activeTab = activeDraggingTab
                    }
                    activeDraggingTab = nil
                },
            /// do not use isActive  ->
            /// as it will immediate disabled when tab is moved as it checks drag value
            isEnabled: activeTab == tab
        )
    }
}

#Preview {
    DraggableTabBariOS18DemoView()
}
