//
//  FullScreenVideoView.swift
//  animation

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
