//
//  AnimatedTabView.swift
//  animation
//
//  Learning point
//  ──────────────
//  iOS 17 equivalent of the symbolEffect-on-selection demo. Uses the
//  pre-iOS-18 `.tabItem`-style TabView, drives bounce animation via
//  per-tab `AnimatedTab` model objects (`isAnimating: Bool?`), and
//  exposes a runtime toggle to flip bounce direction (up vs down).
//  Pairs with `TabStateScrollView` (project helper) for tab-bar
//  hide-on-scroll behavior.
//
//  Key APIs
//  ────────
//  • `.tabItem { Image; Text }` — old-school TabView item builder.
//  • `.symbolEffect(.bounce.up.byLayer / .down.byLayer, value:)`
//  • `withAnimation(_:completionCriteria: .logicallyComplete) { ... } completion: { ... }`
//    — the two-phase animation pattern: animate, then on logical
//    completion clear the trigger inside a transaction with
//    `disablesAnimations = true` so the next state change doesn't
//    re-animate.
//  • `.toolbar(_ visibility, for: .tabBar)` — iOS 17 spelling of the
//    visibility modifier.
//  • `TabStateScrollView` (project helper) — observes scroll direction
//    and writes `Visibility` back to a binding.
//
//  How to apply
//  ────────────
//  Use when the deployment target still includes iOS 17. The bounce-
//  direction picker is illustrative — production apps usually pick one
//  direction and stick with it for consistent feedback.
//
//  See also
//  ────────
//  • AnimatedTabBariOS18.swift — iOS 18+ rewrite using the typed
//    `Tab` API and per-tab effect variation.
//

import SwiftUI

struct TabbarAnimationApp: App {
    var body: some Scene {
        WindowGroup {
            AnimatedTabView()
        }
    }
}

struct AnimatedTabView: View {
    /// View properties
    @State private var activeTab: TabiOS17 = .photos
    @State private var tabState: Visibility = .visible

    /// All tabs
    @State private var allTabs: [AnimatedTab] = TabiOS17.allCases.compactMap { tab -> AnimatedTab? in
        return .init(tab: tab)
    }

    /// Bounce properties
    @State private var bounceDown: Bool = true
    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $activeTab) {
                NavigationStack {
                    TabStateScrollView(axis: .vertical, showsIndicator: false, tabState: $tabState) {
                        VStack(spacing: 15) {
                            ForEach(profiles) { profile in
                                GeometryReader(content: { geometry in
                                    let size = geometry.size

                                    Image(profile.profilePicture)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: size.width, height: size.height)
                                        .clipShape(.rect(cornerRadius: 12))
                                })
                                .frame(height: 380)
                            }
                        }
                    }
                    .navigationTitle(TabiOS17.photos.title)
                }

//                .setupTab(.photos, tabState)
                .toolbar(tabState, for: .tabBar)
                .animation(.easeInOut(duration: 0.3), value: tabState)
                .tabItem {
                    Image(systemName: TabiOS17.photos.rawValue)
                    Text(TabiOS17.photos.title)
                }

                NavigationStack {
                    VStack {}
                        .navigationTitle(TabiOS17.chat.title)
                }
                .setupTab(.chat)
                .tabItem {
                    Image(systemName: TabiOS17.chat.rawValue)
                    Text(TabiOS17.chat.title)
                }

                NavigationStack {
                    VStack {}
                        .navigationTitle(TabiOS17.apps.title)
                }
                .setupTab(.apps)
                .tabItem {
                    Image(systemName: TabiOS17.apps.rawValue)
                    Text(TabiOS17.apps.title)
                }

                NavigationStack {
                    VStack {}
                        .navigationTitle(TabiOS17.notifications.title)
                }
                .setupTab(.notifications)
                .tabItem {
                    Image(systemName: TabiOS17.notifications.rawValue)
                    Text(TabiOS17.notifications.title)
                }

                NavigationStack {
                    VStack {}
                        .navigationTitle(TabiOS17.profile.title)
                }
                .setupTab(TabiOS17.profile)
                .tabItem {
                    Image(systemName: TabiOS17.profile.rawValue)
                    Text(TabiOS17.profile.title)
                }
            }

            Picker("", selection: $bounceDown) {
                Text("Bounces Down")
                    .tag(true)

                Text("Bounces Up")
                    .tag(false)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 15)
            .padding(.bottom, 20)

            customTabBar()
        }
    }

    /// Custom Tab Bar
    @ViewBuilder
    func customTabBar() -> some View {
        HStack(spacing: 0) {
            ForEach($allTabs) { $animatedTab in
                let tab = animatedTab.tab

                VStack(spacing: 4) {
                    Image(systemName: tab.rawValue)
                        .font(.title2)
                        // animates the image when the value changes, might see animate twice
                        // use transaction to disable it
                        .symbolEffect(bounceDown ?
                            .bounce.down.byLayer : .bounce.up.byLayer,
                            value: animatedTab.isAnimating)

                    Text(tab.title)
                        .font(.caption2)
                        .textScale(.secondary)
                }
                .frame(maxWidth: .infinity)
                .foregroundStyle(activeTab == tab ? Color.primary : Color.gray.opacity(0.8))
                .padding(.top, 15)
                .padding(.bottom, 10)
                .contentShape(.rect)
                .onTapGesture { // can use button too
                    withAnimation(.bouncy, completionCriteria: .logicallyComplete, {
                        activeTab = tab
                        animatedTab.isAnimating = true
                    }, completion: {
                        var transaction = Transaction()
                        transaction.disablesAnimations = true
                        withTransaction(transaction) {
                            animatedTab.isAnimating = nil
                        }
                    })
                }
            }
        }
    }
}

extension View {
    @ViewBuilder
    func setupTab(_ tab: TabiOS17) -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity)
            .tag(tab)
    }
}

#Preview {
    AnimatedTabView()
}
