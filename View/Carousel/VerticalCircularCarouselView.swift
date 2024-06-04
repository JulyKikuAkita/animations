//
//  VerticalCircularCarouselView.swift
//  animation

import SwiftUI

struct VerticalCircularCarouselDemoView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
        }
        .padding()
    }
}
struct VerticalCircularCarouselView: View {
    var body: some View {
        GeometryReader {
            let size = $0.size
            
            ScrollView(.vertical) {
                LazyVStack(spacing: 0) {
                    ForEach(creditCards) { card in
                        CardView(card)
                            .frame(width: 220, height: 150)
                            .visualEffect { content, geometryProxy in
                                content
                                    .offset(x: -150)
                                    .rotationEffect(
                                        .init(degrees: cardRotation(geometryProxy)),
                                        anchor: .center)
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                .scrollTargetLayout() // turn scroll view to snap carousel
            }
            // 75 is half of the card height
            .safeAreaPadding(.vertical, (size.height * 0.5) - 75) //make carousel start at the center point
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned(limitBehavior: .always)) // turn scroll view to snap carousel
            .overlay { // testing
                Divider()
                    .background(.black)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
    
    @ViewBuilder
    func CardView(_ card: CreditCard) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25.0)
                .fill(card.color.gradient)
            
            /// Card details
            VStack(alignment: .leading, spacing: 10) {
                Image(.bitcoin)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40)
                
                Spacer(minLength: 0)
                
                HStack(spacing: 0) {
                    ForEach(0..<3, id: \.self) { _ in
                            Text("****")
                        Spacer(minLength: 0)
                    }
                    
                    Text(card.number)
                        .offset(y: -2)
                }
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.bottom, 20)
                
                HStack {
                    Text(card.name)
                    Spacer(minLength: 0)
                    Text(card.date)
                }
                .font(.caption.bold())
                .foregroundStyle(.white)
            }
            .padding(25)
        }
    }
    
    /// Card rotation
    func cardRotation(_ proxy: GeometryProxy) -> CGFloat {
        return 30
        // TODO: https://www.youtube.com/watch?v=AmArOSpxuMQ&list=PLimqJDzPI-H97JcePxWNwBXJoGS-Ro3a-&index=110
        // 4:14
    }
}

#Preview {
    VerticalCircularCarouselView()
}
