//
//  PlayerAnimationView.swift
//  animation
//
//  Created by IFang Lee on 3/2/24.
//

import SwiftUI
import SwiftData

struct PlayerAnimationView: View {
    /// For smooth custom drawing path tab bar animation
    @Namespace private var animation
    /// View properties
    @State private var activeTab: VideoTab = .home
    @State private var config: PlayerConfig = .init()
    @State private var hideNavBar: Bool = true
    @State private var tabState: Visibility = .visible
    /// View properties - custom path tab bar
    @State private var tabShapePosition: CGPoint = .zero

    @State private var selectedColor: DummyColors = .blue
    /// Context
    @Environment(\.modelContext) private var context
    /// Stored colors, need to register ColorTransformer() class
    @Query private var storedColors: [ColorModel]
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $activeTab) {
                HomeTabView()
                    .setupTab(.home)
                
                FullScreenVideoView()
                    .setupTab(.shorts)
                
                ProfileListView()
                    .setupTab(.progress)
                
                BasicProfileAnimationListView()
                .setupTab(VideoTab.profile)
                
                CardCarouselView()
                    .setupTab(.carousel)
            }
            .padding(.bottom, tabBarHeight)
            
            /// Mini-player View
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
            
            CustomTabBar(selectedColor.color)
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
                    HStack {
                        ForEach(storedColors, id: \.color) { color in
                            ZStack {
                                Circle().fill(Color(color.color).gradient)
                                    .frame(width: 35, height: 35)
                                Text(String(color.name.first ?? "M"))
                                    .font(.callout)
                                    .foregroundColor(selectedColor.color)
                            }
                        }
                    }
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
                    FloatingAction(symbol: "dog.fill", background: DummyColors.red.color) {
                        selectedColor = .red
                        insertColorModels() // this crash preview
                    }
                    
                    FloatingAction(symbol: "pawprint.fill", background: DummyColors.orange.color) {
                        selectedColor = .orange
                        insertColorModels() // this crash preview
                    }
                    
                    FloatingAction(symbol: "fish.fill", background: DummyColors.accent.color) {
                        selectedColor = .accent
                        insertColorModels() // this crash preview
                    }
                    
                    FloatingAction(symbol: "cat.fill", background: DummyColors.green.color) {
                        selectedColor = .green
                        insertColorModels() // this crash preview
                    }
                    
                    FloatingAction(symbol: "bird.fill", background: DummyColors.brown.color) {
                        selectedColor = .brown
                        insertColorModels() // this crash preview
                        
                    }
                } label: { isExpanded in
                    Image(systemName: "plus")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .rotationEffect(.init(degrees: isExpanded ? 45 : 0))
                        .scaleEffect(1.02)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(selectedColor.color.gradient, in: .circle)
                        .shadow(color: .black.opacity(0.5), radius: 6)
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
                    HStack{
                        Button(action: {
                            hideNavBar.toggle()
                        }, label: {
                            Image(systemName: hideNavBar ? "eye.slash" : "eye")
                                .foregroundColor(selectedColor.color)
                        })
                        
                        Button(action: {
                            deleteColorModels()
                        }, label: {
                            Image(systemName: "trash.fill")
                                .foregroundColor(selectedColor.color)
                        })
                    }
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
                    .foregroundColor(selectedColor.color)
                
                VStack(alignment: .leading, spacing: 4, content: {
                    Text(item.title)
                        .font(.callout)
                        .foregroundColor(selectedColor.color)
                    
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
    func CustomTabBar(_ tint: Color, _ inactiveTint: Color = .gray) -> some View {
        /// Moving all the remaining tab items' to the bottom
        HStack(alignment: .bottom, spacing: 0) {
            ForEach(VideoTab.allCases, id: \.rawValue) { tab in
                VideoTabItem(
                    tint: tint,
                    inactiveTint: inactiveTint, 
                    tab: tab, 
                    animation: animation,
                    activeTab: $activeTab, 
                    position: $tabShapePosition
                )
            }
        }
        .frame(height: tabBarHeight)
        .padding(.horizontal, 15)
        .padding(.vertical, 10)
        .background(content: {
            TabShape(midpoint: tabShapePosition.x)
                .fill(.white)
                .ignoresSafeArea()
                /// adding blur + shadow for shape smoothing
                .shadow(color: tint.opacity(0.2), radius: 5, x: 0, y: -5)
                .blur(radius: 2)
                .padding(.top, 25)
        })
        /// adding animation
        .animation(.interactiveSpring(response: 0.6, dampingFraction: 0.7, blendDuration: 0.7), value: activeTab)
    }
    
    func insertColorModels() {
        let colorModel = ColorModel(name: selectedColor.rawValue, color: selectedColor.color)
        context.insert(colorModel)
    }
    
    func deleteColorModels() {
        do {
            try context.delete(model: ColorModel.self)
        } catch {
            print("Failed to delete all ColorModel.")
        }
    }
}

/// Custom tab bar item
struct VideoTabItem: View {
    var tint: Color
    var inactiveTint: Color
    var tab: VideoTab
    var animation: Namespace.ID
    @Binding var activeTab: VideoTab
    @Binding var position: CGPoint

    /// Each tab item position on the screen
    @State private var tabPosition: CGPoint = .zero
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: tab.symbol)
                .font(.title3)
                .foregroundColor(activeTab == tab ? .white : tint)
                /// increasing size for the active tab
                .frame(width: activeTab == tab ? 60 : 30, height: activeTab == tab ? 60 : 30)
                .background {
                    if activeTab == tab {
                        Circle()
                            .fill(tint.gradient)
                            .matchedGeometryEffect(id: "ACTIVETAB", in: animation)
                    }
                }
            
            Text(tab.rawValue)
                .font(.caption2)
                .foregroundColor(activeTab == tab ? tint : .gray)
        }
        .frame(maxWidth: .infinity)
        .contentShape(.rect)
        .viewPosition(completion: { rect in
            tabPosition.x = rect.midX
            
            /// updating active tab position
            if activeTab == tab {
                position.x = rect.midX
            }
            
        })
        .onTapGesture {
            activeTab = tab
            /// need below animation block due to TabShape.animatableData didn't work
            withAnimation(.interactiveSpring(response: 0.6, dampingFraction: 0.7, blendDuration: 0.7)) {
                position.x = tabPosition.x
            }
        }
    }
}

extension View {
    @ViewBuilder
    func setupTab(_ tab: VideoTab) -> some View {
        self
            .tag(tab)
            /// hiding native tab bar
            .toolbar(.hidden, for: .tabBar)
    }
    
    /// Safe area value (increase bottom padding for tab bar)
    var safeArea: UIEdgeInsets {
        if let safeArea = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.keyWindow?.safeAreaInsets {
            return safeArea
        }
        return .zero
    }
    
    var tabBarHeight: CGFloat { // 20 is the custom curve path
        return 49 + safeArea.bottom
    }
}

#Preview {
    ContentView()
}
