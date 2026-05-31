//
//  iOS26+MinimizableTabBar.swift
//  animation
//
//  Learning point
//  ──────────────
//  Two ways to hide a tab bar on scroll:
//
//    NATIVE (commented out at the bottom):
//      `.tabBarMinimizeBehavior(.onScrollDown)` — one line, iOS 26+,
//      handled by the system. Use this when you can.
//
//    MANUAL (the active code):
//      `.onScrollGeometryChange` + `.onScrollPhaseChange` track scroll
//      direction and phase, then drive `.toolbarVisibility(.hidden,
//      for: .tabBar)`. Worth studying because the same building blocks
//      (phase + offset + a "stored offset" anchor) generalize to any
//      scroll-reactive UI: floating headers, snap-to-top buttons, etc.
//
//  Key APIs
//  ────────
//  • `.tabBarMinimizeBehavior(.onScrollDown)` — native one-liner.
//  • `.onScrollGeometryChange(for:of:action:)` — observe content
//    offset (relative to top inset) without a GeometryReader.
//  • `.onScrollPhaseChange { _, phase in }` — gate state changes to
//    the `.interacting` phase so the bar doesn't flicker during
//    deceleration.
//  • `.toolbarVisibility(.hidden, for: .tabBar)` — animatable hide.
//  • `Tab(role: .search) {}` + `.tabViewBottomAccessory { ... }` —
//    bonus pieces showing the iOS 26 search-tab + accessory pattern.
//
//  How to apply
//  ────────────
//  Reach for the native modifier on iOS 26+. Keep the manual version
//  if you need: (a) a custom threshold, (b) iOS < 26 support, or
//  (c) bar visibility tied to something OTHER than scroll direction
//  (e.g. content-based visibility).
//
//  See also
//  ────────
//  • LiquidGlassSearchableTabbar.swift — `.tabBarMinimizeBehavior`
//    in a fuller example with a tabViewBottomAccessory mini-player.
//
import SwiftUI

@available(iOS 26.0, *)
struct MinimizedTabbarDemoView: View {
    @State private var isScrolledUp: Bool = false
    @State private var storedOffset: CGFloat = 0
    @State private var scrollPhase: ScrollPhase = .idle
    @State private var tabBarVisibility: Visibility = .visible
    let tabBarThreshold: CGFloat = 50
    let optionalDownThreshold: CGFloat = 10
    var body: some View {
        TabView {
            Tab("For You", systemImage: "heart.text.square.fill") {
                ScrollView(.vertical) {
                    VStack(spacing: 12) {
                        ForEach(1 ... 50, id: \.self) { _ in
                            Rectangle()
                                .fill(.fill.tertiary)
                                .frame(height: 50)
                        }
                    }
                    .padding(15)
                }
                .onScrollGeometryChange(for: CGFloat.self) {
                    $0.contentOffset.y + $0.contentInsets.top
                } action: { oldValue, newValue in
                    let isScrolledUp = oldValue < newValue
                    if self.isScrolledUp != isScrolledUp {
                        storedOffset = newValue - (tabBarVisibility == .hidden ? (optionalDownThreshold + tabBarThreshold) : 0)
                        self.isScrolledUp = isScrolledUp
                    }

                    let diff = newValue - storedOffset
                    if scrollPhase == .interacting {
                        tabBarVisibility = diff > tabBarThreshold ? .hidden : .visible
                    }
                }
                .onScrollPhaseChange { _, newPhase in
                    scrollPhase = newPhase
                }
                .toolbarVisibility(tabBarVisibility, for: .tabBar)
                .animation(
                    .smooth(duration: 0.3, extraBounce: 0),
                    value: tabBarVisibility
                )
            }

            Tab("Products", systemImage: "macbook.and.iphone") {}

            Tab("More", systemImage: "safari") {}

            Tab("Bag", systemImage: "bag") {}

            Tab(role: .search) {}
        }
        .tabViewBottomAccessory {
            Text("From $9.99, get 10% off on your first purchase!\nUse code: WELCOME10")
                .font(.caption)
                .multilineTextAlignment(.center)
        }
        // .tabBarMinimizeBehavior(.onScrollDown) // native
    }
}

@available(iOS 26.0, *)
#Preview {
    MinimizedTabbarDemoView()
}
