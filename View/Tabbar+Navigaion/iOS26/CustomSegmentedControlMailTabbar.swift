//
//  CustomSegmentedControlMailTabbar.swift
//  animation
//
//  Created on 6/1/26.
//
//  Learning point
//  ──────────────
//  A Gmail-style segmented tab bar where exactly one tab is "expanded"
//  (icon + label inside a colored capsule) and the rest collapse to
//  icon-only chips of equal width. Selection animates as a width
//  redistribution: the active capsule grows to fit its title, the
//  others share what's left.
//
//  Key APIs / techniques
//  ─────────────────────
//  • `.onGeometryChange(for: CGSize.self)` per label — measures each
//    title's intrinsic width so the active capsule can size to match
//    without a hard-coded width or truncation.
//  • `fixedSize(horizontal: true, vertical: false)` paired with
//    `.frame(width: isActive ? nil : 0)` — keeps the text at its
//    natural width when active and collapses it to zero when inactive,
//    while still letting `.onGeometryChange` capture its real size.
//  • Cross-faded `Capsule` backgrounds (inactive fill vs. active tint)
//    with opacity instead of swapping views — keeps layout stable.
//  • `.geometryGroup()` — animates each tab as a single unit so the
//    icon, label, and capsule interpolate together (no stutter).
//  • `.animation(animation.speed(isActive ? 1 : 2.5))` — asymmetric
//    speeds: fade-in is calm, fade-out is snappy, so the active label
//    "owns" the transition.
//  • `interpolatingSpring(duration: 0.3, bounce: 0)` — non-bouncy
//    spring; tabs feel responsive without overshoot.
//  • `DragGesture(minimumDistance: 20)` — large enough to coexist with
//    a parent vertical `ScrollView` without hijacking its scroll.
//  • `previousTab` state — enables tap-active-tab-to-toggle and
//    swipe-right-to-restore behaviors without external coordination.
//

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
        /// range 1-5, Cap at 5; beyond that the inactive chips get too narrow to be tappable.
        Array(Tab.allCases.prefix(3))
    }

    var body: some View {
        let isLastTabActive: Bool = selection == allTabs.last
        return GeometryReader {
            let containerSize = $0.size
            let activeTitleWidth: CGFloat = tabTitleSizes[selection]?.width ?? 0
            /// Symbol: 20, Horizontal padding: 40, Spacing: 6
            let activeWidth: CGFloat = activeTitleWidth + 20 + 40 + 6
            /// When the last tab is active there's no peek affordance, so only the
            /// active tab itself is removed from the inactive width pool. Otherwise
            /// we also reserve room for the "peeking" last tab → remove 2.
            let removeCount: Int = isLastTabActive ? 1 : min(allTabs.count - 1, 2)
            let tabSpacing = CGFloat(allTabs.count - removeCount) * spacing
            let inActiveWidth: CGFloat = (containerSize.width - activeWidth - tabSpacing) / CGFloat(allTabs.count - removeCount)
            HStack(spacing: spacing) {
                ForEach(allTabs, id: \.title) { tab in
                    tabItemView(tab, inActiveWidth: inActiveWidth)
                }
            }
        }
        /// Lets the last tab peek off the trailing edge as a swipe affordance,
        /// except when it's already active (nothing left to swipe to).
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
        /// `minimumDistance: 20` keeps the parent ScrollView's vertical pan
        /// uninterrupted; only deliberate horizontal drags reach this gesture.
        DragGesture(minimumDistance: 20)
            .onEnded { value in
                let xTranslation = value.translation.width
                guard abs(xTranslation) > 40 else { return }
                if xTranslation > 0 {
                    /// Swipe right → restore the previously active tab.
                    guard let previousTab else { return }
                    selection = previousTab
                } else {
                    /// Swipe left → jump to the last tab (peeking on the right).
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
                /// `fixedSize` keeps the text at its natural width so
                /// `.onGeometryChange` reports the *real* title size, even while
                /// the outer frame collapses it to 0 in the inactive state.
                .fixedSize(horizontal: true, vertical: false)
                .lineLimit(1)
                .onGeometryChange(for: CGSize.self) {
                    $0.size
                } action: { newValue in
                    tabTitleSizes[tab] = newValue
                }
                .frame(width: isActive ? nil : 0, alignment: .leading)
                /// Asymmetric animation speed: inactive labels fade out 2.5x
                /// faster so the active label visually "wins" the transition.
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
        /// Treats the tab (icon + label + capsule) as one unit during animation
        /// so children interpolate together instead of independently jittering.
        .geometryGroup()
        .onTapGesture {
            /// Tapping the already-active tab toggles between it and the last
            /// tab — a quick way to peek "All Mail" and bounce back.
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
