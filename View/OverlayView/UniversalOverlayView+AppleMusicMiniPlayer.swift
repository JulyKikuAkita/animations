//
//  UniversalOverlayView+AppleMusicMiniPlayer.swift
//  animation
//
//  Standalone demo (not wired into the app's demo browser; preview-only).
//  iOS 18+ — uses the iOS 18 `Tab(_:systemImage:)` API and the
//  same `Group(subviews:)`-era patterns elsewhere in the project.
//
//  Learning point
//  ──────────────
//  Composes [[ExpandableMusicPlayerView]] (drag-to-expand mini-player
//  with UIWindow tilt) inside a [[UniversalOverlayView]] host so the
//  player floats ABOVE a `TabView`. This is the smallest possible
//  recipe for "Apple Music–style mini-player attached to a tab bar"
//  in this codebase — three lines do all the work:
//
//      .universalOverlay(show: $showMiniPlayer) {
//          ExpandableMusicPlayerView(show: $showMiniPlayer)
//      }
//      .onAppear { showMiniPlayer = true }
//
//  Reading this file is the right entry point for understanding how
//  the two underlying systems compose. Each system stands alone:
//    • `RootView` + `.universalOverlay` — the "render above
//      everything" plumbing.
//    • `ExpandableMusicPlayerView` — the player UI itself.
//  This file just glues them together.
//
//  Why the player needs the universal overlay
//  ──────────────────────────────────────────
//  Without it, the player would render inside the active Tab's
//  view tree and be replaced when the user switches tabs. With the
//  universal overlay, the player lives in a SEPARATE UIWindow and
//  persists across tab switches, sheets, and modals — like the real
//  Apple Music mini-player.
//
//  Key APIs
//  ────────
//  • `Tab(_:systemImage:)` — iOS 18 typed-Tab API; replaces the
//    older `Tab(...)` with positional args.
//  • `.universalOverlay(show:content:)` — project helper from
//    [[UniversalOverlayView]].
//  • `RootView { ... }` — the wrapping `RootView` MUST be at the
//    Preview root so the `UniversalOverlayProperties` environment is
//    available. Without it, the overlay silently does nothing.
//  • `AppleMusicTab` — project enum holding tab identity + system
//    image name.
//
//  How to apply
//  ────────────
//  Use this file as the template for any "persistent mini-player"
//  UI in a tabbed app. Wrap your real `App` body in `RootView { ... }`
//  and attach `.universalOverlay(show: ...)` wherever the player
//  should appear.
//
//  See also
//  ────────
//  • UniversalOverlayView.swift — the infrastructure powering this
//    demo. Read its header for the architecture details.
//  • View/MiniPlayerView/ExpandableMusicPlayerView.swift — the
//    player view itself (UIWindow-tilt mechanics).
//  • View/MiniPlayerView/MiniPlayerView.swift — alternative tab-
//    bar-INTEGRATED mini-player; same drag mechanics but lives in
//    the host view tree, so doesn't survive tab switches. Compare
//    when picking an architecture.
//
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
