//
//  ReelView.swift
//  animation
//
//  Learning point
//  ──────────────
//  Single reel cell for the vertical paged feed. Owns its own
//  `AVPlayer` + `AVPlayerLooper` so videos play seamlessly in a
//  loop, auto-pause when scrolled away, restart from the
//  beginning when the user returns, and tear down completely on
//  disappear to free decoder resources.
//
//  Five reusable mechanics
//  ───────────────────────
//    1. **`AVPlayerLooper` for seamless looping** —
//          let queue = AVQueuePlayer(playerItem: playerItem)
//          looper = AVPlayerLooper(player: queue, templateItem: playerItem)
//       The looper auto-rebuilds the queue each cycle, giving
//       FRAME-PERFECT loops with no flash/seek artifact between
//       cycles. Required: an `AVQueuePlayer`, the source
//       template item, and you must hold a strong reference to
//       the looper (here via `@State`).
//    2. **Visibility-aware play/pause via `OffsetKey`** —
//       `GeometryReader { $0.frame(in: .scrollView(axis: .vertical)) }`
//       reports the reel's offset within the scroll. When more
//       than half the video is on-screen, play; otherwise, pause.
//       `.preference(key: OffsetKey.self) + .onPreferenceChange`
//       is the iOS 16+ pattern; for iOS 17+ swap to `.onGeometryChange`
//       (faster, no preference plumbing).
//    3. **Restart when fully off-screen** —
//          if rect.minY >= size.height || -rect.minY >= size.height {
//              player?.seek(to: .zero)
//          }
//       When the reel is completely above OR below the visible
//       region, rewind so the next time the user scrolls back
//       to it, playback starts from frame 0. Matches Reels /
//       TikTok behaviour.
//    4. **Player lifecycle in `onAppear` / `onDisappear`** —
//       Build player only ONCE per cell instance (`guard player == nil`),
//       and tear it down on disappear (`player = nil`). This
//       prevents zombie decoders during fast scroll, which is
//       what causes "video stuck on first frame" and battery
//       drain.
//    5. **Double-tap-to-like with positional bursts** —
//       `onTapGesture(count: 2, perform: { position in ... })`
//       receives the LOCAL tap position, which becomes the
//       origin for the floating heart in the parent's `[Like]`
//       overlay. `withAnimation(_, completionCriteria: .logicallyComplete)`
//       fires the cleanup AFTER the heart's animation lands.
//
//  Why guard against multiple likes
//  ────────────────────────────────
//      reel.isLiked = true // make sure multiple double taps only like once
//
//  Each double-tap appends a heart burst (visual feedback), but
//  the underlying `reel.isLiked` flag flips ONCE — matching
//  YouTube/Instagram semantics where you can spam-tap for
//  emoji bursts but the like state is binary.
//
//  Why `.symbolEffect(.bounce, value: reel.isLiked)` on the heart button
//  ─────────────────────────────────────────────────────────────────────
//  iOS 17+ symbol-bounce animation that fires whenever
//  `reel.isLiked` toggles — not just when the user taps the
//  button directly. So a double-tap on the video also bounces
//  the heart icon down in the controls column. Free polish.
//
//  Key APIs
//  ────────
//  • `AVQueuePlayer` + `AVPlayerLooper` — the seamless-loop
//    recipe.
//  • `.preference(key:value:)` + `.onPreferenceChange` — geometry
//    bubbling (pre-iOS 17 pattern; uses project's `OffsetKey`).
//  • `.onTapGesture(count: 2)` — double-tap with position.
//  • `.symbolEffect(.bounce, value:)` — value-driven SF Symbol
//    animation.
//  • `withAnimation(_, completionCriteria: .logicallyComplete)` —
//    iOS 17+ completion handler.
//
//  How to apply
//  ────────────
//  Use as the cell template for any vertical-paged video feed:
//  reels, shorts, in-app stories, video documentation. The
//  visibility-driven play/pause + per-cell ownership +
//  appearance-bound lifecycle is the architectural lesson.
//
//  See also
//  ────────
//  • FullScreenVideoView.swift — parent feed that hosts this
//    cell.
//  • ZoomVideoDetailView.swift — sibling that uses
//    `onScrollVisibilityChange` (iOS 18+) instead of preference
//    keys for the same play/pause logic.
//  • CustomVideoPlayer.swift — the AVPlayerViewController
//    bridge.
//

import AVKit
import SwiftUI

struct ReelView: View {
    @Binding var reel: Reel
    @Binding var likedCounter: [Like]
    var size: CGSize
    var safeArea: EdgeInsets
    /// View Properties
    @State private var player: AVPlayer?
    @State private var looper: AVPlayerLooper?
    var body: some View {
        GeometryReader {
            let rect = $0.frame(in: .scrollView(axis: .vertical))

            /// Custom Video Player  view
            CustomVideoPlayer(player: $player)
                /// Offset update
                .preference(key: OffsetKey.self, value: rect)
                .onPreferenceChange(OffsetKey.self, perform: { value in
                    playPause(value)
                })
                .overlay(alignment: .bottom, content: {
                    reelDetailsView()
                })
                /// Double tap like animation
                .onTapGesture(count: 2, perform: { position in
                    let id = UUID()
                    likedCounter.append(.init(id: id, tappedRect: position, isAnimated: false))
                    /// Animating like
                    withAnimation(.snappy(duration: 1.2), completionCriteria: .logicallyComplete) {
                        if let index = likedCounter.firstIndex(where: { $0.id == id }) {
                            likedCounter[index].isAnimated = true
                        }
                    } completion: {
                        /// Removing like, once it's finished
                        likedCounter.removeAll(where: { $0.id == id })
                    }

                    /// Liking the reel
                    reel.isLiked = true // make sure multiple double taps only like the reel once
                })
                /// Creating Player
                .onAppear {
                    guard player == nil else { return }
                    guard let bundleID = Bundle.main.path(forResource: reel.videoID, ofType: "mp4") else { return }
                    let videoURL = URL(filePath: bundleID)

                    let playerItem = AVPlayerItem(url: videoURL)
                    let queue = AVQueuePlayer(playerItem: playerItem)
                    looper = AVPlayerLooper(player: queue, templateItem: playerItem)

                    player = queue
                }
                /// Clearing Player
                .onDisappear {
                    player?.pause()
                    player = nil
                }
        }
    }

    /// Play/pause action for Reel video
    func playPause(_ rect: CGRect) {
        let halveVideoHeight = rect.height * 0.5
        if -rect.minY < halveVideoHeight && rect.minY < halveVideoHeight {
            player?.play()
        } else {
            player?.pause()
        }

        /// release video to it's original position should restart play video from the beginning
        if rect.minY >= size.height || -rect.minY >= size.height {
            player?.seek(to: .zero)
        }
    }

    /// Reel details & controls
    func reelDetailsView() -> some View {
        HStack(alignment: .bottom, spacing: 10) {
            VStack(alignment: .leading, spacing: 8, content: {
                HStack(spacing: 10) {
                    Image(systemName: "person.circle.fill")
                        .font(.largeTitle)

                    Text(reel.videoID)
                        .font(.callout)
                        .lineLimit(1)
                }
                .foregroundStyle(.white)

                Text(reel.description)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .clipped()
            })

            Spacer(minLength: 0)

            /// Controls View
            VStack(spacing: 35) {
                Button("", systemImage: reel.isLiked ? "suit.heart.fill" : "suit.heart") {
                    reel.isLiked.toggle()
                }
                .symbolEffect(.bounce, value: reel.isLiked)
                .foregroundStyle(reel.isLiked ? .red : .white)

                Button("", systemImage: "message") {}

                Button("", systemImage: "paperplane") {}

                Button("", systemImage: "ellipsis") {}
            }
            .font(.title2)
            .foregroundStyle(.white)
        }
        .padding(.leading, 15)
        .padding(.trailing, 10)
        .padding(.bottom, safeArea.bottom + 15)
    }
}

// struct CustomVideoPlayer: UIViewControllerRepresentable {
//    @Binding var player: AVPlayer?
//    func makeUIViewController(context: Context) -> AVPlayerViewController {
//        let controller = AVPlayerViewController()
//        controller.player = player
//        controller.videoGravity = .resizeAspectFill
//        controller.showsPlaybackControls = false
//
//        return controller
//    }
//
//    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
//        /// updating player
//        uiViewController.player = player
//    }
// }
