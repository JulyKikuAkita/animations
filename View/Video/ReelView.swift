//
//  ReelView.swift
//  animation

import SwiftUI
import AVKit

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
                    ReelDetailsView()
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
    @ViewBuilder
    func ReelDetailsView() -> some View {
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
                
                Button("", systemImage: "message") {
                }
                
                Button("", systemImage: "paperplane") {
                }
                
                Button("", systemImage: "ellipsis") {
                }
            }
            .font(.title2)
            .foregroundStyle(.white)
        }
        .padding(.leading, 15)
        .padding(.trailing, 10)
        .padding(.bottom, safeArea.bottom + 15)
    }
}

//struct CustomVideoPlayer: UIViewControllerRepresentable {
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
//}

#Preview {
    ContentView()
}
