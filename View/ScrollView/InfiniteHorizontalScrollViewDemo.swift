//
//  InfiniteHorizontalScrollViewDemo.swift
//  animation
import SwiftUI

struct InfiniteHorizontalScrollViewDemo: View {
    var body: some View {
        InfiniteHorizontalScrollView()
    }
}

struct InfiniteHorizontalScrollView: View {
    @State private var activeCard: PhotoItem? = sampleItems.first
    var body: some View {
        ZStack {
            AmbientBackground()
            
            VStack(spacing: 40) {
                ScrollView(.horizontal) {
                    HStack(spacing: 10) {
                        ForEach(sampleItems) { card in
                                CarouselCardView(card)
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .containerRelativeFrame(.vertical) { value, _ in
                    value * 0.45
                }
            }
            .safeAreaPadding(15)
        }
    }
    
    @ViewBuilder
    private func AmbientBackground() -> some View {
        GeometryReader {
            let size = $0.size
            
            ZStack {
                ForEach(sampleItems) { card in
                    Image(uiImage: card.image ?? UIImage(systemName: "photo")!)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .ignoresSafeArea()
                        .frame(width: size.width, height: size.height)
                        .opacity(activeCard?.id == card.id ? 1 : 0)
                }
                
                Rectangle()
                    .fill(.black.opacity(0.45))
                    .ignoresSafeArea()
            }
            .compositingGroup()
            .blur(radius: 90, opaque: true)
        }
    }
    
    @ViewBuilder
    private func CarouselCardView(_ card: PhotoItem) -> some View {
        GeometryReader {
            let size = $0.size
            
            Image(uiImage: card.image ?? UIImage(systemName: "photo")!)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size.width, height: size.height)
                .clipShape(.rect(cornerRadius: 20))
                .shadow(color: .black.opacity(0.4), radius: 10, x: 1, y: 0)
        }
        .frame(width: 220)
        .scrollTransition(.interactive.threshold(.centered), axis: .horizontal) { content, phase in
            content
                .offset(y: phase == .identity ? -10 : 0)
                .rotationEffect(.degrees(phase.value * 5), anchor: .bottom)
        }
    }
}

#Preview {
    InfiniteHorizontalScrollViewDemo()
}
