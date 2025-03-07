//
//  CardCarouselWithScrollTransitionsAPI.swift
//  animation
//  iOS 18 API
import SwiftUI

struct CardCarouselWithScrollTransitionsAPIView: View {
    var body: some View {
        NavigationStack {
            GeometryReader {
                let size = $0.size
                ParallaxCarousel18View(size: size)
            }
        }
        .safeAreaPadding(.horizontal, 15)
        .frame(height: 330)
    }

    @ViewBuilder
    func ParallaxCarousel18View(size: CGSize) -> some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 10) {
                ForEach(firstSetCards) { card in

                    Image(card.image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size.width + 80) // 80 is the offset value
                        .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                            content
                                .offset(x: phase == .identity ? 0 : -phase.value * 80)
                        }
                        .frame(width: 220, height: size.height)
                        .clipShape(.rect(cornerRadius: 25))
                        .shadow(color: .black.opacity(0.25), radius: 8, x: 5, y: 10)
                }
            }
            .padding(.horizontal, 30)
            .scrollTargetLayout()
            .frame(height: size.height, alignment: .top)
        }
        .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
        .safeAreaPadding(.horizontal, 15)
        .scrollIndicators(.hidden)
    }

    /// Demo blur + scale scroll View
    @ViewBuilder
    func ScaleCarousel18View(size: CGSize) -> some View {
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
                        }

                }
            }
            .scrollTargetLayout()
        }
        .scrollClipDisabled()
        .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
        .scrollIndicators(.hidden)
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
    StackCardCarouselView()
}

/// Stack card carousel
struct StackCardCarouselView: View {
    var body: some View {
        NavigationStack {
            GeometryReader {
                let size = $0.size
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 10) {
                        ForEach(firstSetCards) { card in
                            let index = Double(firstSetCards.firstIndex(where: { $0.id == card.id }) ?? 0)

                            GeometryReader {
                                let minX = $0.frame(in: .scrollView(axis: .horizontal)).minX

                                Image(card.image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 220, height: size.height)
                                    .clipShape(.rect(cornerRadius: 25))
                                    .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                                        content
                                            .blur(radius: phase == .identity ? 0 : 2, opaque: false)
                                            .scaleEffect(phase == .identity ? 1: 0.9, anchor: .bottom)
                                            .offset(y: phase == .identity ? 0 : -10)
                                            .rotationEffect(.init(degrees: phase == .identity ? 0 : phase.value * 5), anchor: .bottomTrailing)
                                            .offset(x: minX < 0 ? minX / 2 : -minX)
                                    }
                            }
                            .frame(width: 220)
                            .zIndex(-index)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollClipDisabled()
                .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
                .safeAreaPadding(.horizontal, (size.width - 220) / 2)
            }
        }
        .safeAreaPadding(.horizontal, 15)
        .frame(height: 330)
    }
}
