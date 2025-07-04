//
//  AnimatedTabView.swift
//  animation

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
