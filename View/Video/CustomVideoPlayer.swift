//
//  CustomVideoPlayer.swift
//  animation
//
//  Learning point
//  ──────────────
//  Minimal SwiftUI bridge to `AVPlayerViewController` — the
//  building block every video demo in this folder shares. Wrap
//  an `AVPlayer?` `@Binding` and get a SwiftUI-friendly view
//  that:
//    • Hides the system playback controls so you can build your
//      own (Reels-style overlay, custom gestures, etc).
//    • Uses `.resizeAspectFill` so video fills the frame even
//      if its native aspect ratio differs (cropping rather than
//      letterboxing — the YouTube Shorts / Instagram Reels
//      look).
//
//  Why a `@Binding<AVPlayer?>` instead of `AVPlayer`
//  ─────────────────────────────────────────────────
//  Players are heavy objects. Letting the parent view OWN the
//  optional player means it can:
//    • Set it to `nil` on `.onDisappear` to release decoder
//      resources.
//    • Swap players (e.g. when paging between reels) without
//      re-creating this view.
//    • Tear down + recreate during memory pressure without the
//      child needing to know.
//
//  Why `UIViewControllerRepresentable` (not `UIViewRepresentable`)
//  ───────────────────────────────────────────────────────────────
//  `AVPlayerViewController` is a UIKit view CONTROLLER, not a
//  view. Using the controller representable preserves the
//  built-in lifecycle (audio session management, picture-in-
//  picture support, AirPlay, automatic Now-Playing-Center
//  integration) — all of which break if you try to extract just
//  its view via `AVPlayerLayer` directly.
//
//  Why `showsPlaybackControls = false`
//  ───────────────────────────────────
//  Every consumer in this folder
//  ([[FullScreenVideoView]], [[ReelView]],
//  [[ZoomVideoDetailView]]) draws their own controls overlay.
//  Hiding the system chrome avoids visual conflicts and gives
//  you full design control.
//
//  Key APIs
//  ────────
//  • `UIViewControllerRepresentable` — SwiftUI ↔ UIKit-VC bridge.
//  • `AVPlayerViewController.videoGravity = .resizeAspectFill` —
//    fill mode (vs `.resizeAspect` letterbox or `.resize` stretch).
//  • `AVPlayer` (parent-owned) — playback engine; pair with
//    `AVPlayerLooper` for looping content (see `[[ReelView]]`).
//
//  How to apply
//  ────────────
//  Drop this in any time you need video in SwiftUI without
//  surrendering control. Pair with parent-owned `AVPlayer`,
//  drive play/pause via `.onChange` or `.onScrollVisibilityChange`,
//  and add your own controls as overlays.
//
//  See also
//  ────────
//  • ReelView.swift — uses this with `AVPlayerLooper` for
//    seamless looping reels.
//  • ZoomVideoDetailView.swift — uses this with paged scroll +
//    `onScrollVisibilityChange` to play only the visible reel.
//  • FullScreenVideoView.swift — top-level container demo.
//

import AVKit
import SwiftUI

struct CustomVideoPlayer: UIViewControllerRepresentable {
    @Binding var player: AVPlayer?
    func makeUIViewController(context _: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspectFill
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context _: Context) {
        uiViewController.player = player
    }
}
