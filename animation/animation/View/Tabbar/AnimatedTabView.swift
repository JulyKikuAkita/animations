//
//  AnimatedTabView.swift
//  animation
//
//  Created by IFang Lee on 2/27/24.
//

import SwiftUI

struct AnimatedTabView: View {
    /// View properties
    @State private var activeTab: Tab = .apps
    /// All tabs
    @State private var allTabs: [AnimatedTab] = Tab.allCases.compactMap { tab -> AnimatedTab? in
        return .init(tab: tab)
    }
    /// Bounce properties
    @State private var bounceDown: Bool = true
    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $activeTab) {
                NavigationStack {
                    VStack {
                        
                    }
                    .navigationTitle(Tab.photos.title)
                }
                .setupTab(.photos)
                
                NavigationStack {
                    VStack {
                        
                    }
                    .navigationTitle(Tab.chat.title)
                }
                .setupTab(.chat)
                
                NavigationStack {
                    VStack {
                        
                    }
                    .navigationTitle(Tab.apps.title)
                }
                .setupTab(.apps)
                
                NavigationStack {
                    VStack {
                        
                    }
                    .navigationTitle(Tab.notifications.title)
                }
                .setupTab(.notifications)
                
                NavigationStack {
                    VStack {
                        
                    }
                    .navigationTitle(Tab.profile.title)
                }
                .setupTab(.profile)
                
            }
            
            Picker("", selection: $bounceDown) {
                Text("Bounces Down")
                    .tag(true)
                
                Text("Bounces Up")
                    .tag(false)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal,15)
            .padding(.bottom, 20)
            
            CustomTabBar()
        }
    }
    
    /// Custom Tab Bar
    @ViewBuilder
    func CustomTabBar() -> some View {
        HStack(spacing: 0) {
            ForEach($allTabs) { $animatedTab in
                let tab = animatedTab.tab
                
                VStack(spacing: 4) {
                    Image(systemName: tab.rawValue)
                        .font(.title2)
                    // animates the image when the value changes, might see animate twice
                    // use transaction to disable it
                        .symbolEffect( bounceDown ?
                            .bounce.down.byLayer : .bounce.up.byLayer ,
                            value: animatedTab.isAnimating
                        )
                    
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
    func setupTab( _ tab: Tab) -> some View {
        self
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .tag(tab)
    }
}
#Preview {
    ContentView()
}
