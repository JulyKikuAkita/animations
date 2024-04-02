//
//  FullScreenVideoView.swift
//  animation

import SwiftUI
import AVKit

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
                }
            }
        }
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.paging)
        .background(.black)
        .environment(\.colorScheme, .dark)
    }
        
}

struct ReelView: View {
    @Binding var reel: Reel
    @Binding var likedCounter: [Like]
    var size: CGSize
    var safeArea: EdgeInsets
    /// View Properties
    @State private var player: AVPlayer?
    var body: some View {
        GeometryReader { _ in
            /// Custom Video Player  view
            CustomVideoPlayer(player: $player)
        }
    }
    
}

struct CustomVideoPlayer: UIViewControllerRepresentable {
    @Binding var player: AVPlayer?
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.videoGravity = .resizeAspectFill
        controller.showsPlaybackControls = false
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        
    }
}
#Preview {
    ContentView()
}
