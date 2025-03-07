//
//  VerticalCircularCarouselView.swift
//  animation

import SwiftUI

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
                                    .offset(x: 150)
                                    .rotationEffect(
                                        .init(degrees: cardRotation(geometryProxy)),
                                        anchor: .leading)
                                    .offset(x: -100, // push view to trailing side
                                            y: -geometryProxy.frame(in: .scrollView(axis: .vertical)).minY)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .scrollTargetLayout() // turn scroll view to snap carousel
            }
            // 75 is half of the card height
            .safeAreaPadding(.vertical, (size.height * 0.5) - 75) //make carousel start at the center point
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned(limitBehavior: .always)) // turn scroll view to snap carousel
//            .overlay { // testing
//                Divider()
//                    .background(.black)
//            }
            .background {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: size.height, height: size.height)
                    .offset(x: -size.height / 2)
            }

            VStack(alignment: .leading, spacing: 12) {
                Button(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/, label: {
                    Image(systemName: "arrow.left")
                        .font(.title3.bold())
                        .foregroundStyle(Color.primary)
                })

                VStack(alignment: .trailing) {
                    Text("Total")
                        .font(.title3.bold())
                        .padding(.top, 10)

                    Text("$999.99")
                        .font(.largeTitle)

                    Text("Choose a card")
                        .font(.caption2)
                        .foregroundStyle(.gray)
                }
                .offset(x: size.width / 2)
            }
            .padding(15)
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
                Image(.fox)
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
    nonisolated func cardRotation(_ proxy: GeometryProxy) -> CGFloat {
        let minY = proxy.frame(in: .scrollView(axis: .vertical)).minY
        let height = proxy.size.height

        let progress = minY / height
        let showCardRange: Double = 3.0 // change how many card to show in above and below
        let angleForEachCard: CGFloat = 50 // your choice of number
        let cappedProgress = progress < 0 ? min(max(progress, -showCardRange), 0) : max(min(progress, showCardRange), 0)  // [-1, 1]

        return cappedProgress * angleForEachCard
    }
}

#Preview {
    VerticalCircularCarouselView()
}
