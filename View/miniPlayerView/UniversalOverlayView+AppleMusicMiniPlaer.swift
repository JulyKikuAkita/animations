//
//  UniversalOverlayView.swift
//  animation
//  iOS 18

import SwiftUI
import AVKit

struct UniversalOverlayAppleMiniPlayerDemoView: View {
    @State private var activeTab: AppleMusicTab = .music
    @State private var showMiniPlayer: Bool = false

    var body: some View {
        TabView {
            Tab.init(
                AppleMusicTab.music.title, systemImage: AppleMusicTab.music.rawValue
            ) {
                Text(AppleMusicTab.music.title)
            }

            Tab.init(AppleMusicTab.browse.title, systemImage: AppleMusicTab.browse.rawValue) {
                Text(AppleMusicTab.browse.title)
            }

            Tab.init(AppleMusicTab.listenNow.title, systemImage: AppleMusicTab.listenNow.rawValue) {
                Text(AppleMusicTab.listenNow.title)
            }

            Tab.init(AppleMusicTab.search.title, systemImage: AppleMusicTab.search.rawValue) {
                Text(AppleMusicTab.search.title)
            }
        }
        .universalOverlay(show: $showMiniPlayer) {
            ExpandableMusicPlayerView(show: $showMiniPlayer)
        }
        .onAppear {
            showMiniPlayer = true
        }
    }
}

#Preview {
    RootView {
        UniversalOverlayAppleMiniPlayerDemoView()
    }
}
