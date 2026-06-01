//
//  CustomSegmenetedControlMailTabbar.swift
//  animation
//
//  Created on 6/1/26.

import SwiftUI

struct CustomSegmentedMailTabBarDemo: View {
    @State private var activeTab: MailTab = .primary
    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                MailTabbar(
                    spacing: 10,
                    trailingVisibility: 0,
                    isGestureEnabled: true,
                    selection: $activeTab
                )
            }
            .safeAreaPadding(15)
            .navigationTitle("Inbox")
        }
    }
}

struct MailTabbar<Tab: MailTabItem>: View {
    var spacing: CGFloat = 8
    var trailingVisibility: CGFloat = 20
    var isGestureEnabled: Bool = false
    @Binding var selection: Tab
    /// View Properties
    /// calculate inactive tab width to for animation
    @State private var tabTitleSizes: [Tab: CGSize] = [:]
    @State private var previousTab: Tab?

    var allTabs: [Tab.AllCases.Element] {
        Array(Tab.allCases.prefix(5))
    }

    var body: some View {
        let isLastTabActive: Bool = selection == allTabs.last
        return GeometryReader {
            let containerSize = $0.size
            let activeTitleWidth: CGFloat = tabTitleSizes[selection]?.width ?? 0
            /// Symbol: 20, Horizontal padding: 40, Spacing: 6
            let activeWidth: CGFloat = activeTitleWidth + 20 + 40 + 6
            let removeCount: Int = isLastTabActive ? 1 : min(allTabs.count - 1, 2)
            let tabSpacing = CGFloat(allTabs.count - removeCount) * spacing
            let inActiveWidth: CGFloat = (containerSize.width - activeWidth - tabSpacing) / CGFloat(allTabs.count - removeCount)
            HStack(spacing: spacing) {
                ForEach(allTabs, id: \.title) { tab in
                    tabItemView(tab, inActiveWidth: inActiveWidth)
                }
            }
        }
        .padding(.trailing, isLastTabActive ? 0 : trailingVisibility)
        .frame(height: 38)
        .contentShape(.rect)
        .gesture(toggleGesture, isEnabled: isGestureEnabled)
        .animation(animation, value: selection)
        .onAppear {
            guard previousTab == nil else { return }
            previousTab = selection
        }
        .onChange(of: selection) { oldValue, _ in
            previousTab = oldValue
        }
    }

    var animation: Animation {
        .interpolatingSpring(duration: 0.3, bounce: 0, initialVelocity: 0)
    }

    var toggleGesture: some Gesture {
        /// to avoid interfere with scroll gesture
        DragGesture(minimumDistance: 20)
            .onEnded { value in
                let xTranslation = value.translation.width
                guard abs(xTranslation) > 40 else { return }
                if xTranslation > 0 {
                    guard let previousTab else { return }
                    selection = previousTab
                } else {
                    guard let lastTab = allTabs.last else { return }
                    selection = lastTab
                }
            }
    }

    func tabItemView(_ tab: Tab, inActiveWidth: CGFloat) -> some View {
        let isActive = selection == tab
        return HStack(spacing: isActive ? 6 : 0) {
            Image(systemName: tab.symbol)
                .font(.body)
                .frame(width: 20)
                .zIndex(1)

            Text(tab.title)
                .font(.callout)
                .fontWeight(.semibold)
                .fixedSize(horizontal: true, vertical: false)
                .lineLimit(1)
                .onGeometryChange(for: CGSize.self) {
                    $0.size
                } action: { newValue in
                    tabTitleSizes[tab] = newValue
                }
                .frame(width: isActive ? nil : 0, alignment: .leading)
                .animation(animation.speed(isActive ? 1 : 2.5)) { content in
                    content
                        .opacity(isActive ? 1 : 0)
                }
        }
        .foregroundStyle(isActive ? tab.activeTint : .gray)
        .padding(.horizontal, isActive ? 20 : 0)
        .frame(maxHeight: .infinity)
        .frame(width: isActive ? nil : inActiveWidth)
        .background {
            ZStack {
                Capsule()
                    .fill(.fill)
                    .opacity(isActive ? 0 : 1)

                Capsule()
                    .fill(tab.activeBackground)
                    .opacity(isActive ? 1 : 0)
            }
        }
        .clipShape(.capsule)
        .contentShape(.capsule)
        .geometryGroup()
        .onTapGesture {
            if let lastTab = allTabs.last, let previousTab, selection == tab {
                if selection == lastTab {
                    selection = previousTab
                } else {
                    selection = lastTab
                }
            }
            selection = tab
        }
    }
}

#Preview {
    CustomSegmentedMailTabBarDemo()
}
