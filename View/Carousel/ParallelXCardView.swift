//
//  ParallelXCardView.swift
//  animation
//
//  Standalone demo (not wired into the app's demo browser; preview-only).
//  Source: https://www.youtube.com/watch?v=3zBSgXoSugU (index 32).
//
//  TODO: Cleanup
//        `ParallaxCarousel17View` (further down this file) is the
//        pre-iOS-18 implementation. It's only referenced from a
//        commented-out call site (search for the `//` line near
//        `ParallaxCarousel17View(size:`). Either delete it or
//        re-enable as a side-by-side demo with the iOS 18 version
//        and explain the contrast in this header.
//
//  Learning point
//  ──────────────
//  Travel-card carousel with parallax: the foreground image slides
//  at one speed while the background overlay (gradient + text) slides
//  at another, producing a layered depth effect. Two implementations
//  live in this file:
//    • `ParallaxCarousel18View` — uses iOS 18 `.scrollTransition` to
//      offset the inner image proportional to the card's phase.
//    • `ParallaxCarousel17View` — uses `visualEffect` + scroll-space
//      `minX` to compute the same offset manually.
//  Both achieve the same look; reading them side-by-side teaches the
//  evolution of the API.
//
//  Key APIs
//  ────────
//  • `.scrollTransition(.interactive)` (iOS 18) — phase-driven
//    offset on the inner image only; outer card stays put.
//  • `.visualEffect { content, proxy in ... }` (iOS 17) — manual
//    `minX` math, equivalent result.
//  • Per-card overlay with linear-gradient mask + caption text — the
//    "card art with credits" look.
//  • `.scrollTargetBehavior(.viewAligned)` + `.scrollTargetLayout()`
//    — paged snap.
//
//  How to apply
//  ────────────
//  Use whenever you want a card to feel "deep" — image at one rate,
//  caption at another. The magic number is the inner-image offset
//  multiplier; ~0.3–0.5× the page width reads as natural parallax.
//
//  See also
//  ────────
//  • CardCarouselWithScrollTransitionsAPI.swift — full catalog of
//    `.scrollTransition` flavors (parallax, scale, circular, stack).
//  • ImageCarouselView.swift — generic reusable version of the
//    progress→effect pattern.
//
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

                    parallaxCarousel18View(size: geometry.size)
                        .offset(x: -minX)
//                    parallaxCarousel17View(size: geometry.size)
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
    func parallaxCarousel18View(size: CGSize) -> some View {
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
                            overlayView(card)
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
    func parallaxCarousel17View(size: CGSize) -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: 10) {
                ForEach(firstSetCards) { card in
                    GeometryReader(content: { proxy in
                        let cardSize = proxy.size
                        /// Simple Parallax effect (1)
                        let minX = proxy.frame(in: .scrollView).minX - 30.0
                        /// Simple Parallax effect (2)
//                      let minX = min((proxy.frame(in: .scrollView).minX - 30.0), proxy.size.width * 1.4)

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
    func overlayView(_ card: Card) -> some View {
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
