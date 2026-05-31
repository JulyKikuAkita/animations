//
//  MiniPlayerView.swift
//  animation
//
//  Created by IFang Lee on 3/2/24.
//
//  ⚠️  Reusable subview, not standalone. Embedded inside the
//      [[PlayerAnimationView]] tab-bar layout. Reads/writes its
//      open/closed state through `Binding<PlayerConfig>`, so the
//      parent (the demo browser) owns the source of truth.
//
//  Learning point
//  ──────────────
//  YouTube-style mini-player that lives ABOVE the tab bar and
//  drags upward into a fullscreen player. The state is driven by
//  one shared `PlayerConfig` (project model) holding `position`,
//  `progress`, `lastPosition`, `selectedPlayerItem`. The view
//  itself is a pure projection of that config — `progress` (0…1)
//  drives every size, opacity, and offset.
//
//  Two design decisions worth understanding:
//    1. **Non-linear `progress` ramp for resizing.**
//       ```
//       let progress = config.progress > 0.7 ? (config.progress - 0.7) / 0.3 : 0
//       ```
//       The mini-player STAYS at miniaturised size for the first
//       70% of the drag, then aggressively widens over the last
//       30%. Without this clamp, the player would start growing
//       immediately on touch — feels twitchy. The 70/30 split is
//       the magic ratio that reads as "drag is starting" vs.
//       "drag is committing to expand."
//    2. **Constrained drag-zones.**
//       ```
//       guard start < playerHeight
//             || start > (size.height - (tabBarHeight + miniPlayerHeight))
//             else { return }
//       ```
//       Drag is only honoured if it BEGINS in the player area
//       (top) or in the mini-bar area (bottom) — touches in the
//       middle scrolling content are passed through to the
//       expanded `ScrollView`. Without this, scrolling the
//       expanded description would dismiss the player.
//
//  Velocity-aware dismiss
//  ──────────────────────
//  On `.onEnded`, the height + `velocity * 5` is compared to
//  `size.height * 0.65`. A flick down dismisses even if the
//  finger only moved a short distance. Same trick as
//  `View/CustomMenu/PopOutMenuView.swift` — `predictedEndTranslation`
//  / `velocity` is what makes drag dismissals feel right.
//
//  Key APIs
//  ────────
//  • `Binding<PlayerConfig>` — the one source of truth; parent
//    owns the actual config.
//  • `DragGesture` `.simultaneously(with: TapGesture())` — tap on
//    the mini-player resets to expanded; drag adjusts position.
//    Simultaneous gestures are essential here because the same
//    container handles both.
//  • `.transition(.offset(y: ...))` — drives the slide-in/out
//    when `selectedPlayerItem` changes.
//  • `.onChange(of: config.selectedPlayerItem, initial: false)` —
//    auto-resets to compact when a new item is loaded.
//
//  How to apply
//  ────────────
//  Use as the template for any tab-bar-anchored mini-player
//  (music, video, podcast). The non-linear progress and
//  constrained drag-zones are the load-bearing UX bits — copy
//  them or expect a twitchy feel. For an OVERLAY (non-tab-bar)
//  mini-player, see [[ExpandableMusicPlayerView]] in the same
//  folder.
//
//  See also
//  ────────
//  • View/MiniPlayerView/ExpandableMusicPlayerView.swift —
//    sibling demo using `UIWindow` reach-through to tilt the
//    underlying app content. Different host model (overlay vs.
//    tab bar), same drag-to-expand mechanics.
//  • View/LandingPages/PlayerAnimationView.swift — the parent
//    that hosts this view inside its custom curved tab bar.
//
import SwiftUI

struct MiniPlayerView: View {
    var size: CGSize
    @Binding var config: PlayerConfig
    var close: () -> Void
    /// Player configuration
    let playerHeight: CGFloat = 200
    let miniPlayerHeight: CGFloat = 50

    /// resize from beginning to end
    var body: some View {
        // let progress = config.progress

        /// resize after drag to 0.7 position
        let progress = config.progress > 0.7 ? (config.progress - 0.7) / 0.3 : 0

        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                GeometryReader {
                    let size = $0.size
                    let width = size.width - 120
                    let height = size.height

                    videoPlayerView()
                        .frame( // 120 is mini-player width
                            width: 120 + (width - (width * progress)),
                            height: height
                        )
                }
                .zIndex(1)

                playerMinifiedContentView()
                    .padding(.leading, 130)
                    .padding(.trailing, 15)
                    .foregroundStyle(Color.primary)
                    .opacity(progress)
            }
            .frame(minHeight: miniPlayerHeight, maxHeight: playerHeight)
            .zIndex(1)

            ScrollView(.vertical) {
                if let playerItem = config.selectedPlayerItem {
                    playerExpandedContentView(playerItem)
                }
            }
            .opacity(1.0 - (config.progress * 1.6)) // faster fade-out when drag down
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background()
        .clipped()
        .contentShape(.rect)
        .offset(y: config.progress * -tabBarHeight)
        // 20 is the curved tab bar height
        .frame(height: size.height + 25 - config.position, alignment: .top)
        .frame(maxHeight: .infinity, alignment: .bottom)
        .gesture(
            DragGesture()
                .onChanged { value in
                    let start = value.startLocation.y
                    // set scroll range for the expanded player view
                    guard start < playerHeight
                        || start > (size.height - (tabBarHeight + miniPlayerHeight)) else { return }

                    let height = config.lastPosition + value.translation.height
                    // stop animation when miniplayer view at miniPlayerHeight
                    config.position = min(height, size.height - miniPlayerHeight)
                    generateProgress()
                }.onEnded { value in
                    let start = value.startLocation.y
                    // set scroll range for the expanded player view
                    guard start < playerHeight
                        || start > (size.height - (tabBarHeight + miniPlayerHeight)) else { return }

                    let velocity = value.velocity.height * 5
                    withAnimation(.smooth(duration: 0.3)) {
                        if (config.position + velocity) > (size.height * 0.65) {
                            config.position = (size.height - miniPlayerHeight)
                            config.lastPosition = config.position
                            config.progress = 1
                        } else {
                            config.resetPosition()
                        }
                    }
                }.simultaneously(with: TapGesture().onEnded { _ in
                    withAnimation(.smooth(duration: 0.3)) {
                        config.resetPosition()
                    }
                })
        )
        /// miniplayer Sliding In/Out
        .transition(.offset(y: config.progress == 1 ? tabBarHeight : size.height))
        .onChange(of: config.selectedPlayerItem, initial: false) { _, _ in
            withAnimation(.smooth(duration: 0.3)) {
                config.resetPosition()
            }
        }
    }

    /// Video Player View
    func videoPlayerView() -> some View {
        GeometryReader {
            let size = $0.size

            Rectangle()
                .fill(.black)

            /// video player view
            if let playerItem = config.selectedPlayerItem {
                Image(playerItem.image)
                    .resizable()
                    .aspectRatio(contentMode: size.height < 60 ? .fill : .fit)
                    .frame(width: size.width, height: size.height)
            }
        }
    }

    /// Player Minified Content view
    @ViewBuilder
    func playerMinifiedContentView() -> some View {
        if let playerItem = config.selectedPlayerItem {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 3, content: {
                    Text(playerItem.title)
                        .font(.callout)
                        .textScale(.secondary)
                        .lineLimit(1)

                    Text(playerItem.author)
                        .font(.caption2)
                        .foregroundStyle(.gray)
                })
                .frame(maxHeight: .infinity)
                .frame(maxHeight: miniPlayerHeight)

                Spacer(minLength: 0)

                Button(action: {}, label: {
                    Image(systemName: "pause.fill")
                        .font(.title2)
                        .frame(width: 35, height: 35)
                        .contentShape(.rect)
                })

                Button(action: close, label: {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .frame(width: 35, height: 35)
                        .contentShape(.rect)
                })
            }
        }
    }

    /// Player ExpandedContent view
    func playerExpandedContentView(_ playerItem: PlayerItem) -> some View {
        VStack(alignment: .leading, spacing: 15, content: {
            Text(playerItem.title)
                .font(.title3)
                .fontWeight(.semibold)

            Text(playerItem.description)
                .font(.callout)
        })
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(15)
        .padding(.top, 10)
    }

    /// calculate progress value [0,1] for miniplayer covering tabbar
    func generateProgress() {
        let progress = max(min(config.position / (size.height - miniPlayerHeight), 1.0), .zero)
        config.progress = progress
    }
}
