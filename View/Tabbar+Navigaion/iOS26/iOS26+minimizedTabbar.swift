//
//  iOS26+MinimizableTabBar.swift
//  animation
//
//  Created on 6/23/25.
// iOS 26 has native modifier of .tabBarMinimizeBehavior(.onScrollDown) for tabViewBottomAccessory content that minimize tabbar during scroll and
// reveal when at the top end of scroll
// The customized implemmntaion using onScrollGeomtryChange hides the tab bar when scroll and reveals after certain scroll distance
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
