//
//  BottomBarTransitionDemo.swift
//  animation
//
//  Created on 9/9/26.

import SwiftUI

/// 26.1 rather than 26.0: `tabViewBottomAccessory(isEnabled:)` is the only member here that needs it.
@available(iOS 26.1, *)
struct BottomBarTransitionIOS27Demo: View {
    @State private var config: PlayerContainerConfig = .init()
    var body: some View {
        TabView {
            Tab.init {
                /// dummy view to illustrate minimize tab behavior
                ScrollView {
                    DummyMessagesView()
                        .foregroundStyle(.clear)
                        .frame(height: 1000)
                }
            } label: {
                AppleMusicTab.browse.tabLabel
            }

            Tab.init {} label: {
                AppleMusicTab.music.tabLabel
            }

            Tab.init {} label: {
                AppleMusicTab.radio.tabLabel
            }

            Tab.init {} label: {
                AppleMusicTab.listenNow.tabLabel
            }

            Tab(role: .search) {} label: {
                AppleMusicTab.search.tabLabel
            }
        }
        /// do not use full screen cover/sheet as it's not compatible with bottom accessory
        .overlay(alignment: .topLeading) {
            if config.attachExpandedPlayer {
                PlayerContainer(config: $config)
                    .transition(.identity)
            }
        }
        .tabViewBottomAccessory(isEnabled: !config.attachExpandedPlayer) {
            PlayerContainer(config: $config)
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .tint(.pink)
    }
}

@available(iOS 26.1, *)
#Preview {
    BottomBarTransitionIOS27Demo()
}
