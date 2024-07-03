//
//  DraggableTabbarView.swift
//  animation

import SwiftUI

struct NormalTabbarView: View {
    var properties: TabProperties = .init()
    
    var body: some View {
        @Bindable var bindings = properties
        VStack(spacing: 0) {
            TabView(selection: $bindings.activeTab) {
                Tab.init(value: 0) {
                    ViewOne()
                        .hideTabBar()
                        .environment(properties)
                }
                
                Tab.init(value: 1) {
                    Text("view2")
                        .hideTabBar()
                }
                
                Tab.init(value: 2) {
                    Text("view3")
                        .hideTabBar()
                }
                
                Tab.init(value: 3) {
                    Text("view4")
                        .hideTabBar()
                }
                
                Tab.init(value: 4) {
                    Text("view5")
                        .hideTabBar()
                }
            }
            
            DraggableTabbarView()
                .environment(properties)
            
        }
    }
}

struct ViewOne: View {
    @Environment(TabProperties.self) private var properties
    var body: some View {
        @Bindable var binding = properties
        NavigationStack {
            List {
                Toggle("Edit Tab Locations", isOn: $binding.editMode)
            }
            .navigationTitle("View 1")
        }
    }
}

struct DraggableTabbarView: View {
    @Environment(TabProperties.self) private var properties
    
    var body: some View {
        @Bindable var binding = properties
        HStack(spacing: 0) {
            ForEach($binding.tabs) { $tab in
                TabBarButton(tab: $tab)
            }
        }
        .padding(.horizontal, 10)
        .background(.bar)
        .coordinateSpace(.named("VIEW"))
    }
}


// Tab bar button
struct TabBarButton: View {
    @Binding var tab: TabModel
    @Environment(TabProperties.self) private var properties
    
    /// View properties
    @State private var tabRect: CGRect = .zero
    var body: some View {
        @Bindable var binding = properties
        Image(systemName: tab.symbolImage)
            .font(.title2)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .foregroundStyle(
                properties.activeTab == tab.idInt ? .primary : .secondary
            )
            .overlay {
                if !properties.editMode {
                    Rectangle()
                        .foregroundStyle(.clear)
                        .contentShape(.rect)
                        .onTapGesture {
                            properties.activeTab = tab.idInt
                        }
                } else {
                    Rectangle()
                        .foregroundStyle(.clear)
                        .contentShape(.rect)
                        .gesture(
                            CustomiOS18Gesture(
                                isEnabled: $binding.editMode,
                                trigger: { status in
                                    if status {
                                        properties.initialTabLocation = tabRect
                                        properties.movingTab = tab.idInt
                                    } else {
                                        
                                    }
                                },
                                onChanged: { offset, location in
                                    
                                })
                        )
                }
            }
            .loopingWiggle(properties.editMode)
            .onGeometryChange(for: CGRect.self) { proxy in
                proxy.frame(in: .named("VIEW"))
            } action: { newValue in
                tabRect = newValue
            }
    }
}

@Observable
class TabProperties {
    /// Shared Tab Properties
    var activeTab: Int = 0
    var editMode: Bool = false
    var tabs: [TabModel] = defaultOrderTabs
    var initialTabLocation: CGRect = .zero
    var movingTab: Int?
    var moveOffset: CGSize = .zero
    var moveLocation: CGPoint = .zero
}

private extension View {
    @ViewBuilder
    func hideTabBar() -> some View {
        self
            .toolbarVisibility(.hidden, for: .tabBar)
    }
    
    @ViewBuilder
    func loopingWiggle(_ isEnabled: Bool = false) -> some View {
        self
            .symbolEffect(.wiggle.byLayer.counterClockwise, isActive: isEnabled)
    }
}

#Preview {
    NormalTabbarView()
}
