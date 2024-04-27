//
//  HorizontalTabView.swift
//  animation
// Use iOS17 scrollPosition tModifier to locate the page view
import SwiftUI

struct HorizontalTabView: View {
    /// View properties
    @State private var tabs: [TabModel] = [
        .init(id: TabModel.HorizonTab.research),
        .init(id: TabModel.HorizonTab.development),
        .init(id: TabModel.HorizonTab.analytics),
        .init(id: TabModel.HorizonTab.audience),
        .init(id: TabModel.HorizonTab.privacy)
    ]
    @State private var activeTab: TabModel.HorizonTab = .research
    @State private var mainViewScrollState: TabModel.HorizonTab? // scroll to view matched tapbar
    @State private var tabBarScrollState: TabModel.HorizonTab? // center selected tab
    @State private var progress: CGFloat = .zero
    
    var body: some View {
        VStack(spacing: 0) {
            HeaderView()
            CustomTabBar()
            
            /// main view
            GeometryReader {
                let size = $0.size
                
                ScrollView(.horizontal) { // require each tab view to be full screen width
                    LazyHStack(spacing: 0) {
                        /// individual tab view
                        ForEach(tabs) { tab in
                            Text(tab.id.rawValue)
                                .frame(width: size.width, height: size.height)
                                .contentShape(.rect)
                        }
                    }
                    .scrollTargetLayout()
                    .rect { rect in
                        progress = -rect.minX / size.width
                    }
                }
                .scrollPosition(id: $mainViewScrollState) // data type needs to match foreach loop data (HorizonTab in this case)
                .scrollIndicators(.hidden)
                .scrollTargetBehavior(.paging)
                // sync tab bar when swipe view
                .onChange(of: mainViewScrollState) { oldValue, newValue in
                    if let newValue {
                        withAnimation(.snappy) {
                            tabBarScrollState = newValue
                            activeTab = newValue
                        }
                    }
                }
            }
        }
    }
    
    /// Header view
    @ViewBuilder
    func HeaderView() -> some View {
        HStack {
            Image(.fox) // youtube logo
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100)
            
            Spacer(minLength: 0)
            
            /// Buttons
            Button("", systemImage: "plus.circle") {
                
            }
            .font(.title2)
            .tint(.primary)
            
            Button("", systemImage: "bell") {
                
            }
            .font(.title2)
            .tint(.primary)
            
            Button(action: {}, label: {
                Image(.fox)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 30, height: 30)
                    .clipShape(.circle)
            })
        }
        .padding(15)
    }
    
    /// Dynamic scrollable tab bar
    @ViewBuilder
    func CustomTabBar() -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: 20) {
                ForEach($tabs) { $tab in
                    Button(action: {
                        withAnimation(.snappy) {
                            activeTab = tab.id
                            mainViewScrollState = tab.id
                            tabBarScrollState = tab.id
                        }
                    }) {
                        Text(tab.id.rawValue)
                            .padding(.vertical, 12)
                            .foregroundStyle(activeTab == tab.id ? Color.primary : .gray)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    //update minX so even when placed the indicator outside the scrollview
                    // scroll indicator also get real time updates
                    .rect { rect in
                        tab.size = rect.size
                        tab.minX = rect.minX
                    }
                }
            }
            .scrollTargetLayout()
        }
        .scrollPosition(id: .init(get: {
            return tabBarScrollState
        }, set: { _ in
            // we only need get
        }), anchor: .center)
        .overlay(alignment: .bottom) { // tab bar indicator
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(.gray.opacity(0.3))
                    .frame(height: 1)
                
                // dynamically set indicator width
                let inputRange = tabs.indices.compactMap{ return CGFloat($0) }
                let outputRange = tabs.compactMap{ return $0.size.width }
                let outputPositionRange = tabs.compactMap{ return $0.minX }

                let indicatorWidth = progress.interpolate(inputRange: inputRange, outputRange: outputRange)
                let indicatorPosition = progress.interpolate(inputRange: inputRange, outputRange: outputPositionRange)
                
                Rectangle()
                    .fill(.primary)
                    .frame(width: indicatorWidth, height: 1.5)
                    .offset(x: indicatorPosition)
            }
        }
        .safeAreaPadding(.horizontal, 15)
        .scrollIndicators(.hidden)
    }
}

/// Use OffsetKey to calculate the width of each tab
///  to position tab indicator properly
extension View {
    @ViewBuilder
    func rect(completion: @escaping (CGRect) -> ()) -> some View {
        self
            .overlay {
                GeometryReader {
                    let rect = $0.frame(in: .scrollView(axis: .horizontal))
                    
                    Color.clear
                        .preference(key: OffsetKey.self, value: rect)
                        .onPreferenceChange(OffsetKey.self, perform: completion)
                }
            }
    }
}
#Preview {
    HorizontalTabView()
}


