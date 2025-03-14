//
//  UniversalOverlayView+AppleMusicMiniPlaer.swift
//  animation
//  iOS 18

import AVKit
import SwiftUI

struct UniversalOverlayAppleMiniPlayerDemoView: View {
    @State private var activeTab: AppleMusicTab = .music
    @State private var showMiniPlayer: Bool = false

    var body: some View {
        TabView {
            Tab(
                AppleMusicTab.music.title, systemImage: AppleMusicTab.music.rawValue
            ) {
                Text(AppleMusicTab.music.title)
            }

            Tab(AppleMusicTab.browse.title, systemImage: AppleMusicTab.browse.rawValue) {
                Text(AppleMusicTab.browse.title)
            }

            Tab(AppleMusicTab.listenNow.title, systemImage: AppleMusicTab.listenNow.rawValue) {
                Text(AppleMusicTab.listenNow.title)
            }

            Tab(AppleMusicTab.search.title, systemImage: AppleMusicTab.search.rawValue) {
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
