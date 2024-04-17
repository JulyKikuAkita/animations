//
//  MiniPlayerView.swift
//  animation
//
//  Created by IFang Lee on 3/2/24.
//

import SwiftUI

struct MiniPlayerView: View {
    var size: CGSize
    @Binding var config: PlayerConfig
    var close: () -> ()
    /// Player configuration
    let playerHeight: CGFloat = 200
    let miniPlayerHeight: CGFloat = 50
    
    var body: some View {
        /// resize from beginning to end
        // let progress = config.progress
        
        /// resize after drag to 0.7 position
        let progress = config.progress > 0.7 ? (config.progress - 0.7) / 0.3 : 0
        
            VStack(spacing: 0) {
                ZStack(alignment: .top) {
                    GeometryReader {
                        let size = $0.size
                        let width = size.width - 120
                        let height = size.height
                        
                        VideoPlayerView()
                            .frame( // 120 is miniplayer width
                                width: 120 + (width - (width * progress)),
                                height: height
                            )
                        
                    }
                    .zIndex(1)
                    
                    PlayerMinifiedContentView()
                        .padding(.leading, 130)
                        .padding(.trailing, 15)
                        .foregroundStyle(Color.primary)
                        .opacity(progress)
                }
                .frame(minHeight: miniPlayerHeight, maxHeight: playerHeight)
                .zIndex(1)
                
                ScrollView(.vertical) {
                    if let playerItem = config.selectedPlayerItem {
                        PlayerExpandedContentView(playerItem)
                    }
                }
                .opacity(1.0 - (config.progress * 1.6)) // faster fade-out when drag down
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(.background)
            .clipped()
            .contentShape(.rect)
            .offset(y: config.progress * -tabBarHeight)
            .frame(height: size.height - config.position, alignment: .top)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let start = value.startLocation.y
                        // set scroll range for the expanded player view
                        guard start < playerHeight || start > (size.height - (tabBarHeight + miniPlayerHeight)) else { return }
                        
                        let height = config.lastPosition + value.translation.height
                        // stop animation when miniplayer view at miniPlayerHeight
                        config.position = min(height, (size.height - miniPlayerHeight))
                        generateProgress()
                    }.onEnded { value in
                        let start = value.startLocation.y
                        // set scroll range for the expanded player view
                        guard start < playerHeight || start > (size.height - (tabBarHeight + miniPlayerHeight)) else { return }
                        
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
            .transition(.offset(y: config.progress == 1 ? tabBarHeight :  size.height))
            .onChange(of: config.selectedPlayerItem, initial: false) { oldValue, newValue in
                withAnimation(.smooth(duration: 0.3)) {
                    config.resetPosition()
                }
            }
    }
    
    /// Video Player View
    @ViewBuilder
    func VideoPlayerView() -> some View {
        GeometryReader {
            let size = $0.size
            
            Rectangle()
                .fill(.black)
            
            /// video player view
            if let playerItem = config.selectedPlayerItem {
                Image(playerItem.image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size.width, height: size.height)
            }
        }
    }
    
    /// Player Minified Content view
    @ViewBuilder
    func PlayerMinifiedContentView() -> some View {
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
                
                Spacer(minLength: /*@START_MENU_TOKEN@*/0/*@END_MENU_TOKEN@*/)
                
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
    @ViewBuilder
    func PlayerExpandedContentView(_ playerItem: PlayerItem) -> some View {
        VStack(alignment: .leading, spacing: 15, content: {
            Text(playerItem.title)
                .font(.title3)
                .fontWeight(.semibold)
            
            Text(playerItem.description)
                .font(.callout)
            
            ParticleEffectsView()
                .scaleEffect(0.7, anchor: .bottomTrailing)
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

#Preview {
    ContentView()
}
