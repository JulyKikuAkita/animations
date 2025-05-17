//
//  ZoomVideoDetailView.swift
//  animation

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
