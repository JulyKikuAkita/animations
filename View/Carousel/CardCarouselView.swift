//
//  CardCarouselView.swift
//  animation
//
//  ⚠️  WIRED INTO THE APP: referenced from
//      `View/LandingPages/PlayerAnimationView.swift:43` — don't rename
//      or delete `CardCarouselView` without updating the demo browser.
//
//  TODO: Cleanup
//        `CarouselView1` and `CarouselView2` (in extensions below)
//        each define a near-identical nested `CardView` — the only
//        meaningful difference is whether the parent ScrollView uses
//        `.scrollTargetBehavior(.viewAligned)`. Hoist the shared
//        `CardView` to a single private struct and pass the
//        scroll-target choice from the parent.
//
//  Learning point
//  ──────────────
//  The headline trick: as a card scrolls past the leading edge, its
//  WIDTH shrinks from 180 → ~50pt while the container slot stays a
//  constant 180pt wide. This is done by reading each card's
//  `frame(in: .scrollView).minX`, mapping that into a 0–130 progress
//  value, and subtracting from the card's natural width — so cards
//  pile up to the left without disturbing the layout of cards still
//  on-screen.
//
//  Two layout flavors are demoed side-by-side:
//    • CarouselView1 — free scroll, no snap; cards reduce smoothly
//      as they leave the leading edge.
//    • CarouselView2 — `.viewAligned` snap; same reduction math but
//      paged.
//  Reading both is the point; they teach the same trick on two
//  different scroll behaviours.
//
//  The file also embeds `CircularCarouselSliderView` and
//  `ParallelXCardView` in a NavigationStack — it's the catch-all
//  carousel demo screen.
//
//  Key APIs
//  ────────
//  • `.containerRelativeFrame(.horizontal, count:span:spacing:)` —
//    iOS 17+. Carves the viewport into N visible slots.
//  • Per-card `GeometryReader` + `proxy.frame(in: .scrollView).minX`
//    + `min(max(progress, 0), 130) / 130` — the reduction math.
//  • `.scrollTargetBehavior(.viewAligned)` (CarouselView2 only) —
//    paged snap.
//  • Custom `DropDown`, `ParticleEffects` etc. live elsewhere; this
//    file just composes them.
//
//  How to apply
//  ────────────
//  Use the reduction trick when you want cards to "tuck away" at an
//  edge instead of just sliding off-screen. Watch the magic numbers
//  (180, 130, 100) — they're tied to `customCardWidth` below; keep
//  them in sync if you change the slot size.
//
//  See also
//  ────────
//  • CircularCarouselSliderView.swift, ParallelXCardView.swift —
//    embedded as additional demos in the same NavigationStack.
//  • CardCarouselWithScrollTransitionsAPI.swift — same reduction
//    feel but using iOS 18 `.scrollTransition(.interactive)` instead
//    of manual minX math.
//
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
            List {
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
                            cardView(card)
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
                            cardView(card)
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
    func cardView(_ card: Card) -> some View {
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
        .frame(width: 180, height: 200)
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
    func cardView(_ card: Card) -> some View {
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
        .frame(width: 180, height: 200)
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
