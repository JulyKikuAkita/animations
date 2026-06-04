//
//  ZoomVideoDetailView.swift
//  animation
//
//  Learning point
//  ──────────────
//  The DESTINATION of the zoom transition started in
//  `[[ZoomTransitionView]]`. Three things happen at once when
//  the user taps a thumbnail: (1) iOS animates the thumbnail's
//  zoom transition to fullscreen, (2) we render the thumbnail
//  on top as a placeholder, (3) a paged ScrollView of all
//  videos sits underneath waiting for the transition to finish
//  before becoming interactive.
//
//  The thumbnail-to-video handoff trick
//  ────────────────────────────────────
//  The video player can't begin loading until layout settles
//  AFTER the zoom animation. If you started the AVPlayer
//  immediately, the video would either:
//    • Flash a black frame while loading.
//    • Compete with the zoom animation for layout.
//  Solution: keep the THUMBNAIL on top (`zIndex` priority) for
//  ~150ms while the zoom plays, THEN flip `hideThumbnail = true`
//  to bring the scroll view forward. By that point, the player
//  has had time to mount and start playing.
//
//      try? await Task.sleep(for: .seconds(0.15))
//      hideThumbnail = true
//
//  150ms is empirically the sweet spot — matches iOS 18's zoom
//  animation duration. Less = flash; more = visible black frame
//  before video loads.
//
//  Why scroll the ID before showing the thumbnail layer
//  ────────────────────────────────────────────────────
//      .task {
//          scrollID = video.id      // line up the scroll position
//          try? await Task.sleep(...)
//          hideThumbnail = true     // then reveal scroll
//      }
//
//  `scrollPosition(id: $scrollID)` programmatically scrolls the
//  paged feed to the right video FIRST. By the time the
//  thumbnail fades and the scroll becomes interactive, the
//  user is already at the right page — no visible jump.
//
//  Why `navigationTransition(.zoom(sourceID:))` swaps IDs
//  ──────────────────────────────────────────────────────
//      .navigationTransition(.zoom(
//          sourceID: hideThumbnail ? scrollID ?? video.id : video.id,
//          in: animation))
//
//  When the user pages within the detail view (scroll-snaps to
//  a different video), the dismiss transition should now zoom
//  back to the THUMBNAIL of THAT video, not the original. We
//  swap `sourceID` to follow `scrollID` once the scroll is
//  active. iOS handles the rest — including matching to the
//  correct `matchedTransitionSource(id:)` in the grid.
//
//  Per-cell play/pause via `onScrollVisibilityChange`
//  ──────────────────────────────────────────────────
//      .onScrollVisibilityChange { isVisible in
//          if isVisible { player?.play() } else { player?.pause() }
//      }
//
//  iOS 18+: SwiftUI fires this callback whenever a scroll cell
//  enters or leaves the visible region. Cleaner than the
//  preference-key + `playPause(rect)` pattern in
//  `[[ReelView]]` (iOS 16/17 era).
//
//  Why also `onGeometryChange` for the rewind condition
//  ────────────────────────────────────────────────────
//      .onGeometryChange(for: Bool.self) { proxy in
//          let minY = proxy.frame(in: .scrollView).minY
//          let height = proxy.size.height * 0.97
//          return -minY < height || minY > height
//      } action: { newValue in
//          if newValue { player?.pause(); player?.seek(to: .zero) }
//      }
//
//  Visibility (above) tells you to play/pause. This SECOND
//  observer triggers a rewind to frame 0 whenever the cell is
//  > 97% off-screen — same UX as Reels where leaving and
//  returning restarts the video from the beginning.
//
//  Key APIs
//  ────────
//  • `.scrollPosition(id:)` — programmatic + observable scroll
//    state.
//  • `.scrollTargetBehavior(.paging)` — discrete page snaps.
//  • `.onScrollVisibilityChange` (iOS 18+) — visibility events
//    per cell.
//  • `.onGeometryChange(for:of:action:)` (iOS 18+) — observe a
//    derived geometry value.
//  • `.navigationTransition(.zoom(sourceID:in:))` — pair to the
//    `matchedTransitionSource` on the grid.
//  • `.zIndex(_:)` — bring the scroll view forward AFTER the
//    transition finishes.
//
//  How to apply
//  ────────────
//  Use this template for any "tap thumbnail → enter paged
//  full-screen feed" — Photos app, Stories viewers, paginated
//  galleries. The thumbnail-to-content handoff via timed
//  `zIndex` flip is the architectural lesson; reuse for any
//  case where you need to mask a slow-loading background while
//  a transition plays.
//
//  See also
//  ────────
//  • ZoomTransitionView.swift — the source grid that initiates
//    the navigation zoom.
//  • CustomVideoPlayer.swift — the AVPlayer bridge.
//  • ReelView.swift — sister cell using preference keys instead
//    of `onScrollVisibilityChange` (iOS 16/17 alternative).
//

import AVKit
import SwiftUI

struct ZoomVideoDetailView: View {
    var video: Video
    var animation: Namespace.ID
    @Environment(VideoSharedModel.self) private var sharedModel
    /// View Properties
    @State private var hideThumbnail: Bool = false
    @State private var scrollID: UUID? /// to know scroll position
    var body: some View {
        GeometryReader {
            let size = $0.size

            Color.black

            ScrollView(.vertical) {
                LazyVStack(spacing: 0) {
                    ForEach(sharedModel.videos) { video in
                        VideoPlayerView(video: video)
                            .frame(width: size.width, height: size.height)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollPosition(id: $scrollID)
            .scrollTargetBehavior(.paging)
            .scrollIndicators(.hidden)
            .zIndex(hideThumbnail ? 1 : 0)

            if let thumbnail = video.thumbnail, !hideThumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size.width, height: size.height)
                    .clipShape(.rect(cornerRadius: 15))
                    .task {
                        scrollID = video.id
                        /// 0.15 second delay to complete the transition animation
                        try? await Task.sleep(for: .seconds(0.15))
                        /// then scroll view move to the front of the ZStack, make the view scrollable
                        hideThumbnail = true
                    }
            }
        }
        .ignoresSafeArea()
        .navigationTransition(.zoom(sourceID: hideThumbnail ? scrollID ?? video.id : video.id, in: animation))
    }
}

struct VideoPlayerView: View {
    var video: Video
    /// View Properties
    @State private var player: AVPlayer?
    var body: some View {
        CustomVideoPlayer(player: $player)
            .onAppear {
                guard player == nil else { return }
                player = AVPlayer(url: video.fileURL)
            }
            .onDisappear {
                player?.pause()
            }
            .onScrollVisibilityChange { isVisible in
                if isVisible {
                    player?.play()
                } else {
                    player?.pause()
                }
            }
            .onGeometryChange(for: Bool.self) { proxy in
                let minY = proxy.frame(in: .scrollView(axis: .vertical)).minY
                let height = proxy.size.height * 0.97

                return -minY < height || minY > height
            } action: { newValue in
                if newValue {
                    player?.pause()
                    player?.seek(to: .zero)
                }
            }
    }
}
