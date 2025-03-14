//
//  ParallelXCardView.swift
//  animation
//  source: https://www.youtube.com/watch?v=3zBSgXoSugU&list=PLimqJDzPI-H97JcePxWNwBXJoGS-Ro3a-&index=32
import SwiftUI

struct ParallelXCardView: View {
    var body: some View {
        NavigationStack {
            TravelCardView()
        }
    }
}

struct TravelCardView: View {
    /// View properties
    @State private var searchText: String = ""
    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 15) {
                HStack(spacing: 12) {
                    Button(action: /*@START_MENU_TOKEN@*/ {}/*@END_MENU_TOKEN@*/, label: {
                        Image(systemName: "line.3.horizontal")
                            .font(.title)
                            .foregroundStyle(.blue)
                    })

                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.gray)

                        TextField("Search", text: $searchText)
                    }
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial, in: .capsule)

                Text("Where do you want to \ntravel?")
                    .font(.largeTitle.bold())
                    .frame(maxWidth: /*@START_MENU_TOKEN@*/ .infinity/*@END_MENU_TOKEN@*/, alignment: .leading)
                    .padding(.top, 10)

                /// Parallax Carousel
                GeometryReader { geometry in
                    let minX = geometry.frame(in: .scrollView).minX - 30.0

                    ParallaxCarousel18View(size: geometry.size)
                        .offset(x: -minX)
//                    ParallaxCarousel17View(size: geometry.size)
                }
                .frame(height: 500)
                .padding(.horizontal, -15)
                .padding(.top, 10)
            }
            .padding(15)
        }
        .scrollIndicators(.hidden)
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
                        .frame(width: size.width, height: size.height)
                        .overlay {
                            OverlayView(card)
                        }
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

    @ViewBuilder
    func ParallaxCarousel17View(size: CGSize) -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: 10) {
                ForEach(firstSetCards) { card in
                    GeometryReader(content: { proxy in
                        let cardSize = proxy.size
                        /// Simple Parallax effect (1)
                        let minX = proxy.frame(in: .scrollView).minX - 30.0
                        /// Simple Parallax effect (2)
//                                    let minX = min((proxy.frame(in: .scrollView).minX - 30.0), proxy.size.width * 1.4)

                        Image(card.image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            // .scaleEffect(1.25)
                            .offset(x: -minX)
                            .frame(width: proxy.size.width * 2.5) // or use scaling -> .scaleEffect(1.25)
                            .frame(width: cardSize.width, height: cardSize.height)
                            .overlay {
                                OverlayView(card)
                                //  Text("\(minX)")
                                //  .font(.largeTitle)
                                //   .foregroundStyle(.white)
                            }
                            .clipShape(.rect(cornerRadius: 15))
                            .shadow(color: .black.opacity(0.25), radius: 8, x: 5, y: 10)
                    })
                    .frame(width: size.width - 60, // size of padding 30
                           height: size.height - 50)
                    /// Scroll Animation
                    .scrollTransition(.interactive, axis: .horizontal) { view, phase in
                        view
                            .scaleEffect(phase.isIdentity ? 1 : 0.95)
                    }
                }
            }
            .padding(.horizontal, 30)
            .scrollTargetLayout() // iOS 17 new scroll api
            .frame(height: size.height, alignment: .top)
        }
        .scrollTargetBehavior(.viewAligned) // iOS 17 new scroll api
        .scrollIndicators(.hidden)
    }

    @ViewBuilder
    func OverlayView(_ card: Card) -> some View {
        ZStack(alignment: .bottomLeading, content: {
            LinearGradient(colors: [
                .clear,
                .clear,
                .clear,
                .clear,
                .clear,
                .black.opacity(0.1),
                .black.opacity(0.5),
                .black,
            ], startPoint: .top, endPoint: .bottom)

            VStack(alignment: .leading, spacing: 4, content: {
                Text(card.title)
                    .font(.title2)
                    .fontWeight(.black)
                    .foregroundStyle(.white)

                Text(card.subTitle)
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.8))
            })
            .padding(20)
        })
    }
}

#Preview {
    ParallelXCardView()
}
