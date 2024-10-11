//
//  CardCarouselWithScrollTransitionsAPI.swift
//  animation
// iOS 18 API
import SwiftUI

struct CardCarouselWithScrollTransitionsAPIView: View {
    var body: some View {
        NavigationStack {
            GeometryReader {
                let size = $0.size
                CircularCarousel18View(size: size)
            }
            
        }
        .safeAreaPadding(.horizontal, 15)
        .frame(height: 330)
    }
    
    /// Demo blur + scale scroll View
    @ViewBuilder
    func CircularCarousel18View(size: CGSize) -> some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 10) {
                ForEach(firstSetCards) { card in

                    Image(card.image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 220, height: size.height)
                        .clipShape(.rect(cornerRadius: 25))
                        .shadow(color: .black.opacity(0.25), radius: 8, x: 5, y: 10)
                        .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                            content
                                .blur(radius: phase == .identity ? 0 : 2, opaque: false)
                                .scaleEffect(phase == .identity ? 1: 0.9, anchor: .bottom)
                                .offset(y: phase == .identity ? 0 : 35)
                                .rotationEffect(.init(degrees: phase == .identity ? 0 : phase.value * 15), anchor: .bottom)
                        }
                       
                }
            }
            .scrollTargetLayout()
        }
        .scrollClipDisabled()
        .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
        .safeAreaPadding(.horizontal, (size.width - 220) / 2 )
        .scrollIndicators(.hidden)
    }
}
        
#Preview {
    CardCarouselWithScrollTransitionsAPIView()
}
