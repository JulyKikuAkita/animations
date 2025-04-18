//
//  Skeleton + Redacted Demo .swift
//  animation
//
import SwiftUI

struct SkeletonViewDemo: View {
    @State private var isLoading: Bool = false
    @State private var cards: [Card] = []
    var body: some View {
        ScrollView {
            VStack {
                if cards.isEmpty {
                    ForEach(0 ..< 3, id: \.self) { _ in
                        CardPlacerHolderView()
                    }
                } else {
                    ForEach(cards) { card in
                        CardPlacerHolderView(card: card)
                    }
                }
            }
            .padding(20)
        }
        .scrollDisabled(cards.isEmpty)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .onTapGesture {
            withAnimation(.smooth) {
                cards = [.init(
                    image: "fox",
                    title: "Redacted Demo Card",
                    subTitle: "From June 9th 2025"
                )]
            }
        }
    }
}

struct CardPlacerHolderView: View {
    var card: Card?
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Rectangle()
                .foregroundStyle(.clear)
                .overlay {
                    if let card {
                        Image(card.image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)

                    } else {
                        SkeletonView(.rect)
                    }
                }
                .frame(height: 220)
                .clipped()

            VStack(alignment: .leading, spacing: 6) {
                if let card {
                    Text(card.title)
                        .fontWeight(.semibold)
                } else {
                    SkeletonView(.rect(cornerRadius: 5))
                        .frame(height: 20)
                }

                Group {
                    if let card {
                        Text(card.subTitle)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    } else {
                        SkeletonView(.rect(cornerRadius: 5))
                            .frame(height: 20)
                    }
                }
                .padding(.trailing, 30)

                ZStack {
                    if card != nil {
                        Text(dummyDescription)
                            .font(.caption)
                            .foregroundStyle(.gray)
                    } else {
                        SkeletonView(.rect(cornerRadius: 5))
                    }
                }
                .frame(height: 50)
                .lineLimit(3)
            }
            .padding([.horizontal, .top], 15)
            .padding(.bottom, 25)
        }
        .background(.background)
        .clipShape(.rect(cornerRadius: 15))
        .shadow(color: .black.opacity(0.1), radius: 10)
    }
}

#Preview {
    SkeletonViewDemo()
}
