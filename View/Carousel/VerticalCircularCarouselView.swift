//
//  VerticalCircularCarouselView.swift
//  animation
//
//  Standalone demo (not wired into the app's demo browser; preview-only).
//
//  Learning point
//  ──────────────
//  Vertical carousel where each card rotates around its LEADING edge
//  as it scrolls — the cards swing open like pages of a Rolodex. The
//  whole thing sits anchored to the left of the viewport so the
//  rotation pivot lines up with the screen edge, which is what gives
//  the "orbiting around an off-screen point" feel.
//
//  Mechanics:
//    • `safeAreaPadding(.vertical, ...)` — half-viewport padding so
//      the first/last card can come to rest at viewport centre.
//    • Each card's `visualEffect` reads its scroll-space `minY` and
//      converts it into a rotation angle via a custom helper
//      (`cardRotation(proxy)`).
//    • `.rotation3DEffect(.degrees(angle), axis: (0, 0, 1), anchor:
//      .leading)` applies the rotation around the leading edge.
//
//  Key APIs
//  ────────
//  • `.visualEffect { content, proxy in ... }` — iOS 17+. Hook for
//    the per-card rotation/offset math.
//  • `.rotation3DEffect(_:axis:anchor:)` with anchor `.leading` —
//    pivot at the left edge for the orbit illusion.
//  • `.scrollTargetBehavior(.viewAligned)` + `.scrollTargetLayout()`
//    — paged snap.
//
//  How to apply
//  ────────────
//  Reach for this when stock vertical scrolling feels flat for a
//  high-stakes UI (loyalty card wallet, premium photo strip). Watch
//  the rotation magnitude — anything past ±45° starts looking
//  cartoonish; the demo's gentler curve is intentional.
//
//  See also
//  ────────
//  • CircularCarouselSliderView.swift — same vertical carousel
//    layout but uses sideways `offset` instead of `rotation3DEffect`
//    to fake the arc. Compare the two — they trade visual punch for
//    different hit-test/clip behaviour.
//  • iPodCarousel+iOS26.swift — horizontal cousin where rotation
//    anchor flips between leading/trailing across centre.
//
import SwiftUI

struct VerticalCircularCarouselView: View {
    var body: some View {
        GeometryReader {
            let size = $0.size

            ScrollView(.vertical) {
                LazyVStack(spacing: 0) {
                    ForEach(creditCards) { card in
                        cardView(card)
                            .frame(width: 220, height: 150)
                            .visualEffect { content, geometryProxy in
                                content
                                    .offset(x: 150)
                                    .rotationEffect(
                                        .init(degrees: cardRotation(geometryProxy)),
                                        anchor: .leading
                                    )
                                    .offset(x: -100, // push view to trailing side
                                            y: -geometryProxy.frame(in: .scrollView(axis: .vertical)).minY)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .scrollTargetLayout() // turn scroll view to snap carousel
            }
            // 75 is half of the card height
            .safeAreaPadding(.vertical, (size.height * 0.5) - 75) // make carousel start at the center point
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
                Button(action: /*@START_MENU_TOKEN@*/ {}/*@END_MENU_TOKEN@*/, label: {
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
    func cardView(_ card: CreditCard) -> some View {
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
                    ForEach(0 ..< 3, id: \.self) { _ in
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
        let showCardRange = 3.0 // change how many card to show in above and below
        let angleForEachCard: CGFloat = 50 // your choice of number
        let cappedProgress = progress < 0 ?
            min(max(progress, -showCardRange), 0) : max(min(progress, showCardRange), 0) // [-1, 1]

        return cappedProgress * angleForEachCard
    }
}

#Preview {
    VerticalCircularCarouselView()
}
