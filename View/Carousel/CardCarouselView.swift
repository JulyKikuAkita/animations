//
//  CardCarouselView.swift
//  animation
// Converting card view to progress value that ranges from 0 to 130 based on the min X value to achieve animation effect
// Each view container size is 180 but view size changes
// Use the progress value to reduce the card width by calculating the previous offset value to keep adjust the current view

import SwiftUI

private let customCardWidth: CGFloat = 100.0

struct CardCarouselView: View {
    
    /// Drop down View properties
    @State private var selection: String?
    @State private var selection2: String?
    @State private var selection3: String?
    
    
    /// Textfield View Properties
    @State private var text: String = ""
    
    var body: some View {
        NavigationStack {
            List{
                CarouselView1(cards: firstSetCards)
                CarouselView2(cards: secondSetCards)
                CircularCarouselSliderView()
                ParallelXCardView()
                randomView()
            }
            .listStyle(.plain)
            .navigationTitle("Carousel Style")
        }
    }
}

extension CardCarouselView {
    @ViewBuilder
    func randomView() -> some View {        
        LimitedTextFieldIView(
            config: .init(
                limit: 10,
                tint: .secondary,
                autoResizes: true
            ),
            hint: "Type here",
            value: $text
        )
        .autocorrectionDisabled()
        .frame(maxHeight: 150)
        
        
        DropDownView(
            hint: "Select",
            options: ["Shiba", "Akita", "Bernes", "Malamute"],
            anchor: .bottom,
            selection: $selection
        )
        
        ParticleEffectsView()
            .scaleEffect(0.7, anchor: .bottom)
            .padding()
        
        DropDownView(
            hint: "Select",
            options: ["list", "grid", "stack"],
            anchor: .bottom,
            selection: $selection2
        )
        
        DropDownView(
            hint: "Select",
            options: ["1", "2", "3"],
            anchor: .top,
            selection: $selection3
        )
    }
}

struct CarouselView1: View {
    @State var cards: [Card]
    var body: some View {
        VStack {
            GeometryReader {
                let size = $0.size
                
                ScrollView(.horizontal) {
                    HStack(spacing: 0) {
                        ForEach(cards) { card in
                            CardView(card)
                        }
                    }
                    .padding(.trailing, size.width - 180)
//                    .scrollTargetLayout()
                }
//                .scrollTargetBehavior(.viewAligned)
                .scrollIndicators(.hidden)
                .clipShape(.rect(cornerRadius: 25))
            }
            .padding(.horizontal, 15)
            .padding(.top, 30)
            .frame(height: 210)
            
            Spacer(minLength: 0)
        }
    }
}

struct CarouselView2: View {
    @State var cards: [Card]
    var body: some View {
        VStack {
            GeometryReader {
                let size = $0.size
                
                ScrollView(.horizontal) {
                    HStack(spacing: 0) {
                        ForEach(cards) { card in
                            CardView(card)
                        }
                    }
                    .padding(.trailing, size.width - 180)
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollIndicators(.hidden)
                .clipShape(.rect(cornerRadius: 25))
            }
            .padding(.horizontal, 15)
            .padding(.top, 30)
            .frame(height: 210)
            
            Spacer(minLength: 0)
        }
    }
}

extension CarouselView1 {
    /// Card view
    @ViewBuilder
    func CardView(_ card: Card) -> some View {
        GeometryReader { proxy in
            let size = proxy.size
            let minX = proxy.frame(in: .scrollView).minX
            /// 190: 180 - card width; 10 - spacing
            let reducingWidth = (minX / 190) * customCardWidth
            let cappedWidth = min(reducingWidth, customCardWidth)
            
            let frameWidth = size.width - (minX > 0 ? cappedWidth : -cappedWidth)
            
            Image(card.image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size.width, height: size.height)
                .frame(width: frameWidth)
                .clipShape(.rect(cornerRadius: 25))
                .offset(x: minX > 0 ? 0 : -cappedWidth) // solved the gapped in progress value
                .offset(x: -card.previousOffset)
        }
        .frame(width: 180, height:  200)
        .offsetX { offset in
            let reducingWidth = (offset / 190) * customCardWidth
            let index = cards.indexOf(card)
            
            if cards.indices.contains(index + 1) {
                cards[index + 1].previousOffset = (offset < 0 ? 0 : reducingWidth)
            }
        }
    }
}

extension CarouselView2 {
    /// Card view
    @ViewBuilder
    func CardView(_ card: Card) -> some View {
        GeometryReader { proxy in
            let size = proxy.size
            let minX = proxy.frame(in: .scrollView).minX
            /// 190: 180 - card width; 10 - spacing
            let reducingWidth = (minX / 190) * customCardWidth
            let cappedWidth = min(reducingWidth, customCardWidth)
            
            let frameWidth = size.width - (minX > 0 ? cappedWidth : -cappedWidth)
            
            Image(card.image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size.width, height: size.height)
                .frame(width: frameWidth)
                .clipShape(.rect(cornerRadius: 25))
                .offset(x: minX > 0 ? 0 : -cappedWidth) // solved the gapped in progress value
                .offset(x: -card.previousOffset)
        }
        .frame(width: 180, height:  200)
        .offsetX { offset in
            let reducingWidth = (offset / 190) * customCardWidth
            let index = cards.indexOf(card)
            
            if cards.indices.contains(index + 1) {
                cards[index + 1].previousOffset = (offset < 0 ? 0 : reducingWidth)
            }
        }
    }
}

#Preview {
    CardCarouselView()
}
