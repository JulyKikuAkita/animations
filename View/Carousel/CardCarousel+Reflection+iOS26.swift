//
//  CardCarousel+Reflection+iOS26.swift
//  animation
//
//  Created on 9/4/25.
//
// Tips to create reflection effect on button edge
// - place a layer of scroll view content on top of the bottom bar
// - clip to match shape
// - add blur

import SwiftUI

struct CarouselWithReflectionDemoView: View {
    @State private var selection: String?

    var body: some View {
        CustomCarouselReflection(cards: firstSetCards) { card in
            print(card.title)
        }
    }
}

struct CustomCarouselReflection: View {
    var cards: [Card]
    var onSelect: (Card) -> Void
    @State private var offsetX: CGFloat = 0
    @State private var currentCard: UUID?
    var body: some View {
        GeometryReader {
            let size = $0.size
            let cardWidth: CGFloat = 273
            let cardHeight = min(max(size.height - 180, 0), 700)
            let horizontalPadding = (size.width - cardWidth) / 2

            ZStack {
                Rectangle()
                    .fill(backgroundColor)
                    .ignoresSafeArea()

                VStack(spacing: 15) {
                    labelView(size: size, cardWidth: cardWidth)

                    ScrollView(.horizontal) {
                        reusableCardStack(cardWidth: cardWidth, cardHeight: cardHeight)
                            .scrollTargetLayout()
                            // ios17+ API, for iOS18+, use onScrollGeometryChange
                            .onGeometryChange(for: CGFloat.self) { // read scroll offset
                                $0.frame(in: .scrollView).minX
                            } action: { newValue in
                                offsetX = newValue
                            }
                    }
                    .scrollIndicators(.hidden)
                    .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
                    .scrollPosition(id: $currentCard, anchor: .center)
                    .safeAreaPadding(.horizontal, horizontalPadding)
                    .frame(height: cardHeight)

                    bottomBar(size: size, cardWidth: cardWidth, cardHeight: cardHeight)
                }
            }
        }
        .onAppear {
            guard currentCard == nil else { return }
            currentCard = cards.first?.id
        }.onChange(of: currentCard) { _, newValue in
            if let newValue, let card = cards.first(where: { $0.id == newValue }) {
                onSelect(card)
            }
        }
    }

    /// light reflection effect
    func bottomBar(size: CGSize, cardWidth: CGFloat, cardHeight: CGFloat) -> some View {
        ZStack {
            let horizontalPadding = (size.width - cardWidth) / 2
            let bottomBarLayout = HStack(spacing: 10) {
                Capsule()
                    .fill(backgroundColor)
                    .frame(width: 220, height: 55)
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 55, height: 55)
            }

            reusableCardStack(cardWidth: cardWidth, cardHeight: cardHeight)
                .padding(.horizontal, horizontalPadding)
                .offset(x: offsetX)
                .frame(width: size.width, height: size.height, alignment: .leading)
                .blur(radius: 10) /// smoothing out with blur
                .frame(height: 60, alignment: .bottom) // only keep the bottom +60 height
                .offset(y: 130) // move to cover bottom bar
                .mask {
                    bottomBarLayout
                        .mask { /// optional
                            LinearGradient(colors: [.white, .white.opacity(0.5), .clear, .clear],
                                           startPoint: .top, endPoint: .bottom)
                        }
                        .offset(x: 33)
                        .offset(y: -1.7)
                }
                .overlay {
                    bottomBarLayout
                        .offset(x: 33)
                }
                .allowsHitTesting(false)

            HStack(spacing: 10) {
                Button {} label: {
                    Text("Customize")
                        .fontWeight(.medium)
                        .frame(width: 220, height: 55)
                        .buttonBackground()
                }

                Button {} label: {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .frame(width: 55, height: 55)
                        .buttonBackground()
                }
            }
            .foregroundStyle(.white)
            // 33 = (55 + 10) / 2
            .offset(x: 33) // align to center
        }
        .frame(height: 60)
        .padding(.top, 10)
    }

    func labelView(size: CGSize, cardWidth: CGFloat) -> some View {
        let progress = offsetX / (cardWidth + 15) // 15 is spacing in reusableCardStack lazyHStack
        let slideOffset = progress * size.width
        return HStack(spacing: 0) {
            ForEach(cards) { card in
                Text(card.title)
                    .font(.title2)
                    .fontWeight(.medium)
                    .frame(width: size.width)
            }
        }
        .offset(x: slideOffset)
        .frame(width: size.width, height: 50, alignment: .leading)
        .foregroundStyle(.white)
    }

    func reusableCardStack(cardWidth: CGFloat, cardHeight: CGFloat) -> some View {
        LazyHStack(spacing: 15) {
            ForEach(cards) { card in
                Image(card.image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: cardWidth, height: cardHeight)
                    .clipShape(.rect(cornerRadius: 40))
            }
        }
    }

    var backgroundColor: Color {
        .black
    }
}

#Preview {
    CarouselWithReflectionDemoView()
}

private extension View {
    func buttonBackground() -> some View {
        background {
            ZStack {
                Capsule()
                    .fill(.white.opacity(0.05))

                Capsule()
                    .stroke(.white.opacity(0.1), lineWidth: 1)
            }
        }
    }
}
