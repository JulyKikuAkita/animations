//
//  AnimatedTabBariOS18.swift
//  animation
//
//  Learning point
//  ──────────────
//  iOS 18 take on the per-tab `symbolEffect` recipe: each tab icon
//  picks ITS OWN animation style (bounce / breathe / wiggle / etc.)
//  triggered exactly once on selection. The trick — fire the trigger,
//  then immediately clear it inside a `Transaction(disablesAnimations: true)`
//  so the symbol effect runs once and doesn't loop.
//
//  Two tab-bar-hide strategies are sketched side-by-side:
//    • `@Observable class TabBarData` (active) — class-level Bool
//      passed via `.environment`; persists per-process, NOT across
//      app launches; works in Xcode previews.
//    • `@SceneStorage("hideTabBar")` (commented out) — persists the
//      flag across launches but does NOT work in previews.
//
//  Key APIs
//  ────────
//  • `Tab(value:) { ... }` — iOS 18 typed-value tab API.
//  • `.symbolEffect(.bounce.byLayer.up / .down, value:)`
//  • `.symbolEffect(.breathe.byLayer, value:)`
//  • `.symbolEffect(.wiggle.left / .backward, options: .speed(_), value:)`
//  • `Transaction().disablesAnimations = true` + `withTransaction` —
//    the "fire-and-forget" pattern for one-shot symbol effects.
//  • `@Observable` + `.environment(_)` — per-process tab-bar visibility.
//  • `.toolbarVisibility(_:for: .tabBar)` — animatable hide.
//  • `.ignoresSafeArea(.keyboard)` — keyboard auto-hides the bar.
//
//  How to apply
//  ────────────
//  Reach for this when tab icons should feel "alive" on selection. Pick
//  ONE animation per tab — applying every effect to every tab muddies
//  the selection feedback.
//
//  See also
//  ────────
//  • AnimatedTabView.swift — the iOS 17 equivalent. Same idea but uses
//    deprecated `.tabItem` and a togglable bounce-direction picker.
//

import SwiftUI

/// option 2: Use observable to show/hide custom tab bar on parent <-> child views
@Observable
class TabBarData {
    var hideTabBar: Bool = false
}

/// option 1: Use SceneStorage to hide/show custom tab bar across full app (SceneStorage does not work in preview)
struct AnimatedTabViewiOS18DemoView: View {
    /// View Properties
    @State private var activeTab: VideoTab = .home
    @State private var symbolEffectTrigger: VideoTab?
    // @SceneStorage("hideTabBar") private var hideTabBar: Bool = false
    var tabBarData = TabBarData()
    var body: some View {
        TabView(selection: .init(get: { activeTab }, set: { newValue in
            activeTab = newValue
            symbolEffectTrigger = newValue
            /// to only trigger tab animation once
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                symbolEffectTrigger = nil
            }
        })) {
            Tab(value: .home) {
                Text("Home")
            }

            Tab(value: .shorts) {
                TextField("Tap me to start typing", text: .constant(""))
                    .overlay(alignment: .topTrailing, content: {
                        Button("Hide TabBar") {
                            /// hideTabBar.toggle() /// for sceneStorage
                            tabBarData.hideTabBar.toggle()
                        }
                        .foregroundStyle(.white)
                        .padding(25)
                    })
                    .toolbarVisibility(tabBarData.hideTabBar ? .hidden : .visible, for: .tabBar)
            }

            Tab(value: .progress) {
                Text("Profile")
            }

            Tab(value: .carousel) {
                dummyScrollView()
                    .overlay(alignment: .topTrailing, content: {
                        Button("Hide TabBar") {
                            /// hideTabBar.toggle() /// for sceneStorage
                            tabBarData.hideTabBar.toggle()
                        }
                        .foregroundStyle(.white)
                        .padding(25)
                    })
                    .toolbarVisibility(tabBarData.hideTabBar ? .hidden : .visible, for: .tabBar)
            }

            Tab(value: .profile) {
                Text("Photos")
            }
        }
        .environment(tabBarData)
        .overlay(alignment: .bottom) {
            animatedTabBar()
                .opacity(tabBarData.hideTabBar ? 0 : 1)
        }
        .ignoresSafeArea(.keyboard, edges: .all) /// this api helps hide tab bar automatically
    }

    func animatedTabBar() -> some View {
        HStack(spacing: 0) {
            ForEach(VideoTab.allCases, id: \.rawValue) { tab in
                VStack(spacing: 4) {
                    Image(systemName: tab.symbol)
                        .font(.title3)
                        .symbolVariant(.fill)
                        .modifiers { content in
                            switch tab {
                            case .home: content.symbolEffect(
                                    .bounce.byLayer.up,
                                    options: .speed(1.2),
                                    value: symbolEffectTrigger == tab
                                )
                            case .profile:
                                content.symbolEffect(
                                    .breathe.byLayer,
                                    value: symbolEffectTrigger == tab
                                )
                            case .carousel:
                                content.symbolEffect(
                                    .wiggle.left,
                                    options: .speed(1.4),
                                    value: symbolEffectTrigger == tab
                                )
                            case .progress:
                                content.symbolEffect(
                                    .bounce.byLayer.down,
                                    options: .speed(2),
                                    value: symbolEffectTrigger == tab
                                )
                            case .shorts:
                                content.symbolEffect(
                                    .wiggle.backward,
                                    options: .speed(1.2),
                                    value: symbolEffectTrigger == tab
                                )
                            }
                        }

                    Text(tab.rawValue)
                        .font(.caption2)
                }
                .foregroundStyle(activeTab == tab ? .blue : .secondary)
                .frame(maxWidth: .infinity)
            }
        }
        .allowsTightening(false)
        .frame(height: 48) /// best for override the original tab height
    }

    func dummyScrollView() -> some View {
        ScrollView {
            VStack {
                ForEach(1 ... 50, id: \.self) { _ in
                    Rectangle()
                        .fill(.green.gradient)
                        .frame(height: 50)
                }
            }
            .padding()
        }
    }
}

private extension View {
    @ViewBuilder
    func modifiers(@ViewBuilder content: @escaping (Self) -> some View) -> some View {
        content(self)
    }
}

#Preview {
    AnimatedTabViewiOS18DemoView()
}
