//
//  ExpandedBottomSheet.swift
//  animation

import SwiftUI

struct ExpandedBottomSheet: View {
    @Binding var expandSheet: Bool
    var animation: Namespace.ID
    /// View properties
    @State private var animateContent: Bool = false
    @State private var offsetY: CGFloat = 0

    var body: some View {
        GeometryReader {
            let size = $0.size
            let safeArea = $0.safeAreaInsets
            
            ZStack {
                Rectangle()
                    .fill(.ultraThickMaterial)
                    .overlay(content: {
                        Rectangle()
                            .fill(Color.black.gradient)
                            .opacity(animateContent ? 1 : 0)
                    })
                    .overlay(alignment: .top) {
                        MusicInfoView(expandSheet: $expandSheet, animation: animation)
                        /// Disabling interaction (since it's not necessary here)
                            .allowsHitTesting(false)
                            .opacity(animateContent ? 0 : 1)
                    }
                    .matchedGeometryEffect(id: "BGVIEW", in: animation)
                
                VStack(spacing: 15) {
                    /// Grab Indicator
                    Capsule()
                        .fill(.gray)
                        .frame(width: 40, height: 5)
                        .opacity(animateContent ? 1 : 0)
                        /// Matching with slide animation
                        .offset(y: animateContent ? 0 : size.height)
                    
                    /// Artwork hero view
                    GeometryReader {
                        let size = $0.size
                        
                        Image("fox")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size.width, height: size.height)
                            .clipShape(RoundedRectangle(cornerRadius: animateContent ? 15 : 5, style: .continuous))
                    }
                    .matchedGeometryEffect(id: "ARTWORK", in: animation)
                    /// For Square artwork image
                    .frame(height: size.width - 50)
                    /// For smaller devices the padding will be 10 and for larger devices the padding will be 30
                    .padding(.vertical, size.height < 700 ? 10 : 30)
                    
                    /// Player view
                    PlayerView(size)
                        /// Moving it from bottom
                        .offset(y: animateContent ? 0 : size.height)
                    
                    
                }
                .padding(.top, safeArea.top + (safeArea.bottom == 0 ? 10 : 0))
                .padding(.bottom, safeArea.bottom  == 0 ? 10 : safeArea.bottom)
                .padding(.horizontal, 25)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .clipped()
                .contentShape(Rectangle())
                .offset(y: offsetY)
                .gesture(
                    DragGesture()
                        .onChanged({ value in
                            let translationY = value.translation.height
                            offsetY = (translationY > 0 ? translationY : 0)
                        }).onEnded({ value in
                            withAnimation(.easeInOut(duration: 0.3)) {
                                if offsetY > size.height * 0.4 {
                                    expandSheet = false
                                    animateContent = false
                                } else {
                                    offsetY = .zero
                                }
                            }
                        })
                )
            }
            .ignoresSafeArea(.container, edges: .all)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.35)) {
                animateContent = true
            }
        }
    }
    
    @ViewBuilder
    func PlayerView(_ mainSize: CGSize) -> some View {
        GeometryReader {
            let size = $0.size
            /// Dynamic spacing using available height
            let spacing = size.height * 0.04
            
            /// Sizing it for more compact look
            VStack(spacing: spacing) {
                VStack(spacing: spacing) {
                    HStack(alignment: .center, spacing: 15) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Hanging Around(Flying Fox)")
                                .foregroundColor(.white)
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Text("Mr Fox")
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Button {
                            
                        } label: {
                            Image(systemName: "ellipsis")
                                .foregroundColor(.white)
                                .padding(12)
                                .background {
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .environment(\.colorScheme, .light)
                                }
                        }
                    }
                    
                    /// Timing indicator
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .light)
                        .frame(height: 5)
                        .padding(.top, spacing)
                    
                    /// Timing label view
                    HStack {
                        Text("0:00")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Spacer(minLength: 0)
                        
                        Text("3:33")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                }
                /// Moving it to top
                .frame(height: size.height / 2.5, alignment: .top)
                
                /// Playback controls
                HStack(spacing: size.width * 0.18) {
                    Button {
                        
                    } label: {
                        Image(systemName: "backward.fill")
                        /// dynamic sizing for smaller to larger iPhones
                            .font(size.height < 300 ? .title3 : .title)
                    }
                    
                    /// making play/pause little bigger
                    Button {
                        
                    } label: {
                        Image(systemName: "pause.fill")
                        /// dynamic sizing for smaller to larger iPhones
                            .font(size.height < 300 ? .largeTitle : .system(size: 50))
                    }
                    
                    Button {
                        
                    } label: {
                        Image(systemName: "forward.fill")
                        /// dynamic sizing for smaller to larger iPhones
                            .font(size.height < 300 ? .title3 : .title)
                    }
                }
                .foregroundColor(.white)
                .frame(maxHeight: .infinity)
                
                /// Volume & other controls
                VStack(spacing: spacing) {
                    HStack(spacing: 15) {
                        Image(systemName: "speaker.fill")
                            .foregroundColor(.gray)
                        
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .environment(\.colorScheme, .light)
                            .frame(height: 5)
                        
                        Image(systemName: "speaker.wave.3.fill")
                            .foregroundColor(.gray)
                    }
                    
                    HStack(alignment: .top, spacing: size.width * 0.18) {
                        Button {
                            
                        } label: {
                            Image(systemName: "quote.bubble")
                                .font(.title2)
                        }
                        
                        VStack(spacing: 6) {
                            Button {
                                
                            } label: {
                                Image(systemName: "airpods.gen3")
                                    .font(.title2)
                            }
                            
                            Text("Nanachi's Airpods")
                                .font(.caption)
                        }
                        
                        
                        Button {
                            
                        } label: {
                            Image(systemName: "list.bullet")
                                .font(.title2)
                        }
                    }
                    .foregroundColor(.gray)
//                    .blendMode(.overlay)
                    .padding(.top, spacing)
                }
                /// Moving it to bottom
                .frame(height: size.height / 2.5, alignment: .bottom)

            }
        }
    }
}

#Preview {
    AppleMusicHomeView()
}

extension View {
    var deviceCornerRadius: CGFloat {
        let key = "_displayCornerRadius"
        if let screen = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.screen {
            if let cornerRadius = screen.value(forKey: key) as? CGFloat {
                return cornerRadius
            }
            
            return 0
        }
        return 0
    }
}
