//
//  PlayerAnimationView.swift
//  animation
//
//  Created by IFang Lee on 3/2/24.
//

import SwiftUI

struct PlayerAnimationView: View {
    /// View properties
    @State private var activeTab: VideoTab = .home
    @State private var config: PlayerConfig = .init()
    @State private var hideNavBar: Bool = true
    @State private var tabState: Visibility = .visible

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $activeTab) {
                HomeTabView()
                    .setupTab(.home)
                
                FullScreenVideoView()
                    .setupTab(.shorts)
                
                VStack {
                    BasicProfileAnimationListView()
                    HStack {
                        RootView {
                            CustomToastView()
                        }
                        CustomAlertDemoView()
                            .environment(SceneDelegate())
                    }
                }
                .setupTab(.subscription)
                
                CardCarouselView()
                    .setupTab(.you)
                
                ProfileListView()
                    .setupTab(VideoTab.profile)
            }
            .padding(.bottom, tabBarHeight)
            
            /// Miniplayer View
            GeometryReader {
                let size = $0.size
                if config.showMiniPlayer {
                    MiniPlayerView(size: size, config: $config) {
                        withAnimation(.easeIn(duration: 0.3), completionCriteria: .logicallyComplete) {
                            config.showMiniPlayer = false
                        } completion: {
                            config.resetPosition()
                            config.selectedPlayerItem = nil
                        }
                    }
                }
            }
            
            CustomTabBar()
                // hide/show tab bar show drag mini player view
                .offset(y: config.showMiniPlayer ? tabBarHeight - (config.progress * tabBarHeight) : 0)
        }
        .ignoresSafeArea(.all, edges: .bottom)
    }
    
    /// Home Tab View
    @ViewBuilder
    func HomeTabView() -> some View {
        NavigationStack {
            ScrollView(.vertical) {
                LazyVStack(spacing: 15) {
                    ForEach(playItems) { item in
                        PlayerItemCardView(item) {
                            config.selectedPlayerItem = item
                            withAnimation(.easeInOut(duration: 0.3)) {
                                config.showMiniPlayer = true
                            }
                        }
                    }
                }
                .padding(15)
            }
            .overlay(alignment: .bottomTrailing) {
                FloatingButton {
                    FloatingAction(symbol: "dog.fill") {
                        print("wow")
                    }
                    
                    FloatingAction(symbol: "pawprint.fill") {
                        print("meow")
                    }
                    
                    FloatingAction(symbol: "fish.fill") {
                        print("puh")
                    }
                    
                    FloatingAction(symbol: "cat.fill") {
                        print("puh")
                    }
                    
                    FloatingAction(symbol: "bird.fill") {
                        print("puh")
                    }
                } label: { isExpanded in
                    Image(systemName: "plus")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .rotationEffect(.init(degrees: isExpanded ? 45 : 0))
                        .scaleEffect(1.02)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.purple.gradient, in: .circle)
                        .shadow(color: .orange.opacity(0.5), radius: 6)
                        ///  scale effect when expanded
                        .scaleEffect(isExpanded ? 0.9 : 1)
                    
                }
                .padding()
            }
            .navigationTitle("YouTube")
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(.background, for: .navigationBar)
            .toolbar(content: {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        hideNavBar.toggle()
                    }, label: {
                        Image(systemName: hideNavBar ? "eye.slash" : "eye")
                    })
                }
            })
            .hideNavBarOnSwipe(hideNavBar)
        }
    }
    
    /// Player Item Card View
    @ViewBuilder
    func PlayerItemCardView(_ item: PlayerItem, onTap: @escaping () -> ()) -> some View {
        VStack(alignment: .leading, spacing: 6, content: {
            Image(item.image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 180)
                .clipShape(.rect(cornerRadius: 10))
                .contentShape(.rect)
                .onTapGesture(perform: onTap)
            
            
            HStack(spacing: 10) {
                Image(systemName: "person.circle.fill")
                    .font(.title)
                
                VStack(alignment: .leading, spacing: 4, content: {
                    Text(item.title)
                        .font(.callout)
                    
                    HStack(spacing: 6) {
                        Text(item.author)
                        
                        Text(". 2 Days ago")
                    }
                    .font(.callout)
                    .foregroundStyle(.gray)
                })
            }
        })
    }
    
    /// Custom Tab Bar
    @ViewBuilder
    func CustomTabBar() -> some View {
        HStack(spacing: 0) {
            ForEach(VideoTab.allCases, id: \.rawValue) { tab in
                VStack(spacing: 4) {
                    Image(systemName: tab.symbol)
                        .font(.title3)
                    
                    Text(tab.rawValue)
                        .font(.caption2)
                }
                .foregroundStyle(activeTab == tab ? Color.primary : .gray)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(.rect)
                .onTapGesture {
                    activeTab = tab
                }
            }
        }
        .frame(height: 49)
        .overlay(alignment: .top) {
                Divider()
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .frame(height: tabBarHeight)
        .background(.background)
    }
}

extension View {
    @ViewBuilder
    func setupTab(_ tab: VideoTab) -> some View {
        self
            .tag(tab)
            .toolbar(.hidden, for: .tabBar)
    }
    
    /// Safearea value (increase bottom padding for tab bar)
    var safeArea: UIEdgeInsets {
        if let safeArea = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.keyWindow?.safeAreaInsets {
            return safeArea
        }
        return .zero
    }
    
    var tabBarHeight: CGFloat {
        return 49 + safeArea.bottom
    }
}

#Preview {
    ContentView()
}
