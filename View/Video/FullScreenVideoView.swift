//
//  FullScreenVideoView.swift
//  animation
//
//  Learning point
//  ──────────────
//  TikTok / Instagram Reels-style vertical paged video feed.
//  Each reel fills the entire screen; vertical swipes snap
//  between reels with `.scrollTargetBehavior(.paging)`. Layered
//  on top: a Like overlay that bursts emoji-hearts from the
//  user's tap location and floats them upward.
//
//  Three reusable mechanics
//  ────────────────────────
//    1. **`containerRelativeFrame(.vertical)` for full-screen
//       paging** — sizes each child to the EXACT scroll
//       container height, so paging snaps to one reel per
//       gesture. `.containerRelativeFrame(.vertical)` is iOS
//       17+'s replacement for the old "size each child to
//       UIScreen.main.bounds" hack — works correctly with
//       split-screen, iPad multitasking, etc.
//    2. **Tap-to-like with positional emoji** — double-tap on
//       any reel adds a `Like` to the parent's `[Like]` array
//       at the tapped position. The overlay reads each like's
//       `tappedRect` and renders a heart there with random
//       rotation, then animates it upward off-screen via two
//       chained `.offset(...)`. Self-removes on completion.
//    3. **Top reels label + camera button + dark scheme** — the
//       global header is an `.overlay(alignment: .top)` on the
//       scroll, so it doesn't interfere with paging gestures.
//       `.environment(\.colorScheme, .dark)` forces dark mode
//       child-wide regardless of system setting (matching the
//       Reels / TikTok aesthetic).
//
//  Why a single shared `[Like]` array (not per-reel)
//  ─────────────────────────────────────────────────
//  Likes can OUTLIVE the reel they originated from (you double-
//  tap reel A, swipe to reel B before the heart finishes
//  animating up). Storing them on the parent's overlay means
//  the in-flight hearts keep rendering correctly even after
//  their source reel scrolled off-screen. Each reel's
//  `onTapGesture(count: 2)` appends to this shared array; the
//  animation completion (in `[[ReelView]]`) removes the entry.
//
//  Why `safeAreaInsets` from the GeometryReader
//  ────────────────────────────────────────────
//  iOS-Reels overlays sit ABOVE the safe area to feel cinematic
//  while text controls (the "Reels" header, reel description)
//  must respect notches and Dynamic Island. Reading
//  `geometry.safeAreaInsets` lets each child pad correctly
//  while the overall video extends edge-to-edge.
//
//  Heart animation mechanics
//  ─────────────────────────
//      .scaleEffect(like.isAnimated ? 1 : 1.8)               // pop in big
//      .rotationEffect(.degrees(like.isAnimated ? 0 : .random(in: -30...30)))  // tilt randomly
//      .offset(x: tapX - 50, y: tapY - 50)                   // anchor at tap
//      .offset(y: like.isAnimated ? -(tapY + safeArea.top) : 0)  // float upward
//
//  Two stacked offsets: the first POSITIONS the heart at the
//  tap location; the second FLOATS it upward off-screen as
//  `isAnimated` flips. Random rotation on appearance gives each
//  burst a slightly different feel — you can tap rapidly and
//  see a satisfying scatter.
//
//  Key APIs
//  ────────
//  • `.containerRelativeFrame(.vertical)` (iOS 17+) — child sizes
//    itself to the scroll container's full vertical span.
//  • `.scrollTargetBehavior(.paging)` — discrete page snaps.
//  • `.animation(.smooth, body: { ... })` — apply animation only
//    to specific properties of a view (scale, rotation), not
//    everything. iOS 17+.
//  • `.environment(\.colorScheme, .dark)` — force scheme on a
//    subtree.
//
//  How to apply
//  ────────────
//  Use as a base for any vertical paged media feed. The
//  parent-owned overlay-likes pattern generalises to any
//  ephemeral interaction that should outlive the cell that
//  triggered it (snap reactions, achievement bursts).
//
//  See also
//  ────────
//  • ReelView.swift — individual reel with the AVPlayer +
//    looper plumbing.
//  • ZoomVideoDetailView.swift — paired list → fullscreen
//    paging with native zoom transition.
//  • CustomVideoPlayer.swift — the AVPlayerViewController
//    bridge every reel uses.
//

import SwiftUI

struct FullScreenVideoView: View {
    var body: some View {
        GeometryReader {
            let size = $0.size
            let safeArea = $0.safeAreaInsets

            VideoView(size: size, safeArea: safeArea)
                .ignoresSafeArea(.container, edges: .all)
        }
    }
}

struct VideoView: View {
    var size: CGSize
    var safeArea: EdgeInsets
    /// View Properties
    @State private var reels: [Reel] = reelsData
    @State private var likedCounter: [Like] = []

    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach($reels) { $reel in
                    ReelView(
                        reel: $reel,
                        likedCounter: $likedCounter,
                        size: size,
                        safeArea: safeArea
                    )
                    .frame(maxWidth: .infinity)
                    .containerRelativeFrame(.vertical)
                }
            }
        }
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.paging)
        .background(.black)
        /// Like animation View
        .overlay(alignment: .topLeading, content: {
            ZStack {
                ForEach(likedCounter) { like in
                    Image(systemName: "suit.heart.fill")
                        .font(.system(size: 75))
                        .foregroundStyle(.red.gradient)
                        .frame(width: 100, height: 100)
                        /// Adding some implicit rotation & scaling animation
                        .animation(.smooth, body: { view in
                            view
                                .scaleEffect(like.isAnimated ? 1 : 1.8)
                                .rotationEffect(.init(degrees: like.isAnimated ? 0 : .random(in: -30 ... 30)))
                        })
                        .offset(x: like.tappedRect.x - 50, y: like.tappedRect.y - 50)
                        ///  Animate hears moving toward y axis
                        .offset(y: like.isAnimated ? -(like.tappedRect.y + safeArea.top) : 0)
                }
            }
        })
        .overlay(alignment: .top, content: {
            Text("Reels")
                .font(.title3)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .overlay(alignment: .trailing) {
                    Button("", systemImage: "camera") {}
                        .font(.title2)
                }
                .foregroundStyle(.white)
                .padding(.top, safeArea.top + 15)
                .padding(.horizontal, 15)
        })
        .environment(\.colorScheme, .dark)
    }
}

#Preview {
    FullScreenVideoView()
}
