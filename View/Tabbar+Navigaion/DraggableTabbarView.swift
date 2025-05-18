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
                Tab(value: 0) {
                    ViewOne()
                        .hideTabBar()
                        .environment(properties)
                }

                Tab(value: 1) {
                    Text("view2")
                        .hideTabBar()
                }

                Tab(value: 2) {
                    Text("view3")
                        .hideTabBar()
                }

                Tab(value: 3) {
                    Text("view4")
                        .hideTabBar()
                }

                Tab(value: 4) {
                    Text("view5")
                        .hideTabBar()
                }
            }

            DraggableTabBarView()
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

struct DraggableTabBarView: View {
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
        .overlay(alignment: .topLeading) {
            if let id = properties.movingTab,
               let tab = properties.tabs.first(where: { $0.idInt == id })
            {
                Image(systemName: tab.symbolImage)
                    .font(.title2)
                    .offset(
                        x: properties.initialTabLocation.minX,
                        y: properties.initialTabLocation.minY
                    )
                    .offset(properties.moveOffset)
            }
        }
        .coordinateSpace(.named("VIEW"))
        .onChange(of: properties.moveLocation) { _, newValue in
            if let droppingIndex = properties.tabs.firstIndex(
                where: { $0.rect.contains(newValue) }),
                let activeIndex = properties.tabs.firstIndex(
                    where: { $0.idInt == properties
                        .movingTab
                    }), droppingIndex != activeIndex
            {
                withAnimation(.snappy(duration: 0.3, extraBounce: 0)) {
                    /// swap items
                    (properties.tabs[droppingIndex],
                     properties.tabs[activeIndex]) = (
                        properties.tabs[activeIndex],
                        properties.tabs[droppingIndex]
                    )
                }

                saveTabBarOrder()
            }
        }
        .sensoryFeedback(.success, trigger: properties.haptics) /// iOS 17+
    }

    private func saveTabBarOrder() {
        let order: [Int] = properties.tabs.reduce([]) { partialResult, model in
            partialResult + [model.idInt]
        }

        UserDefaults.standard.setValue(order, forKey: "DraggableTabBarOrder")
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
            .onGeometryChange(for: CGRect.self) { proxy in
                proxy.frame(in: .named("VIEW"))
            } action: { newValue in
                tabRect = newValue
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .foregroundStyle(
                properties.activeTab == tab.idInt ? .primary : properties.editMode ? .primary : .secondary
            )
            .opacity(properties.movingTab == tab.idInt ? 0 : 1)
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
                                        withAnimation(
                                            .easeInOut(duration: 0.3),
                                            completionCriteria: .logicallyComplete
                                        ) {
                                            /// Finishing with the updated location
                                            /// (Happens when items swapped between one another)
                                            properties.initialTabLocation = tabRect
                                            properties.moveOffset = .zero
                                        } completion: {
                                            properties.moveLocation = .zero
                                            properties.movingTab = nil
                                        }
                                    }
                                },
                                onChanged: { offset, location in
                                    properties.moveOffset = offset
                                    properties.moveLocation = location
                                }
                            )
                        )
                }
            }
            .loopingWiggle(properties.editMode)
            .onGeometryChange(for: CGRect.self) { proxy in
                proxy.frame(in: .global) /// UIKit pan gesture only works on global namespace not custom one
            } action: { newValue in
                tab.rect = newValue
            }
    }
}

@Observable
class TabProperties {
    /// Shared Tab Properties
    var activeTab: Int = 0
    var editMode: Bool = false
    var tabs: [TabModel] = {
        if let order = UserDefaults.standard.value(forKey: "DraggableTabBarOrder") as? [Int] {
            return defaultOrderTabs.sorted { first, second in
                let firstIndex = order.firstIndex(of: first.idInt) ?? 0
                let secondIndex = order.firstIndex(of: second.idInt) ?? 0

                return firstIndex < secondIndex
            }
        }
        return defaultOrderTabs
    }()

    var initialTabLocation: CGRect = .zero
    var movingTab: Int?
    var moveOffset: CGSize = .zero
    var moveLocation: CGPoint = .zero
    var haptics: Bool = false
}

private extension View {
    @ViewBuilder
    func hideTabBar() -> some View {
        toolbarVisibility(.hidden, for: .tabBar)
    }

    @ViewBuilder
    func loopingWiggle(_ isEnabled: Bool = false) -> some View {
        symbolEffect(.wiggle.byLayer.counterClockwise, isActive: isEnabled)
    }
}

#Preview {
    NormalTabbarView()
}
