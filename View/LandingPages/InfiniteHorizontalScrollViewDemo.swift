//
//  InfiniteHorizontalScrollViewDemo.swift
//  animation
//
//  Standalone demo (not wired into the app's demo browser; preview-only).
//  iOS 18+ — uses `onScrollGeometryChange` and the iOS 18
//  `.scrollTransition(.interactive.threshold(.centered))` API.
//
//  Learning point
//  ──────────────
//  Auto-scrolling carousel with two interlocking effects:
//    1. Cards live in an `InfiniteScrollHelper`-backed ScrollView
//       (project helper at `Helpers/Transition/InfiniteScrollHelper.swift`)
//       that duplicates content to fake an endless loop.
//    2. Each card uses `.scrollTransition(.interactive)` to rotate
//       and offset based on its scroll-position phase, so the
//       active card "pops" forward while neighbours recede.
//  Above the carousel, a custom `TitleTextRenderer` (project helper)
//  pulls the title in glyph-by-glyph as the carousel settles.
//
//  Auto-advance: a Combine `Timer.publish(every: 3).autoconnect()`
//  fires every 3 seconds, calls `scrollPosition.scrollTo(...)` on the
//  next card, and a `blurOpacityEffect` extension fades the current
//  card softly between transitions.
//
//  Key APIs
//  ────────
//  • `.scrollTransition(.interactive.threshold(.centered), axis: .horizontal)`
//    — iOS 18. Fires the closure with a phase value as each card
//    crosses the viewport centre.
//  • `.containerRelativeFrame(.vertical)` — pins each card to a
//    consistent vertical extent inside its container.
//  • `onScrollGeometryChange(for:)` — drives the active-card index
//    state without onChange ladders.
//  • `Timer.publish(every:on:in:).autoconnect()` — auto-advance.
//  • `InfiniteScrollHelper` (project) — duplicates content for the
//    seamless loop; see `Helpers/Transition/InfiniteScrollHelper.swift`.
//
//  How to apply
//  ────────────
//  Use whenever you want a hero carousel that auto-rotates AND
//  responds to user touch. The duplicate-content loop is cheaper
//  than head/tail rebound (compare with
//  `View/Carousel/InfiniteCarouselView.swift`).
//
//  See also
//  ────────
//  • View/Carousel/InfiniteCarouselView.swift — alternate
//    seamless-loop technique using head/tail duplicates.
//  • View/Carousel/InfiniteLoopingScrollView.swift — UIKit
//    `UIScrollViewDelegate` reach-through for the same goal.
//  • RotatingIconEffectView.swift — sibling carousel in this
//    folder; button-driven instead of auto-scroll.
//
import SwiftUI

struct InfiniteHorizontalScrollViewDemo: View {
    var body: some View {
        InfiniteHorizontalScrollView()
            .ignoresSafeArea()
    }
}

struct InfiniteHorizontalScrollView: View {
    @State private var activeCard: Card? = firstSetCards.first
    @State private var scrollPosition: ScrollPosition = .init()
    @State private var currentScrollOffset: CGFloat = 0
    @State private var initialAnimation: Bool = false
    @State private var titleProgress: CGFloat = 0
    @State private var scrollPhase: ScrollPhase = .idle
    /// use timer to auto-scroll
    @State private var timer = Timer.publish(every: 0.01, on: .current, in: .default).autoconnect()

    var body: some View {
        ZStack {
            ambientBackground()
                .animation(.easeInOut(duration: 1), value: activeCard)

            VStack(spacing: 40) {
                InfiniteScrollView {
                    ForEach(firstSetCards) { card in
                        carouselCardView(card)
                    }
                }
                .scrollIndicators(.hidden)
                .scrollPosition($scrollPosition)
                .scrollClipDisabled()
                .containerRelativeFrame(.vertical) { value, _ in
                    value * 0.45
                }
                .onScrollPhaseChange { _, newPhase in
                    scrollPhase = newPhase
                }
                .onScrollGeometryChange(for: CGFloat.self) {
                    $0.contentOffset.x + $0.contentInsets.leading
                } action: { _, newValue in
                    currentScrollOffset = newValue

                    if scrollPhase != .decelerating || scrollPhase != .animating {
                        let activeIndex = Int((currentScrollOffset / 220).rounded()) % firstSetCards.count
                        activeCard = firstSetCards[activeIndex]
                    }
                }
                /// move the card deck down
                .visualEffect { [initialAnimation] content, proxy in
                    content
                        .offset(y: !initialAnimation ? -(proxy.size.height + 200) : 0)
                }

                VStack(spacing: 4) {
                    Text("Welcome to")
                        .fontWeight(.semibold)
                        .foregroundStyle(.white.secondary)
                        .blurOpacityEffect(initialAnimation)

                    Text("Apple Invites")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                        .textRenderer(TitleTextRenderer(progress: titleProgress))
                        .padding(.bottom, 12)

                    Text("""
                    Create beautiful invitations for all your events.
                    Anyone can receive invitations.
                    Sending included\n with iCloud+.
                    """)
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.secondary)
                    .blurOpacityEffect(initialAnimation)
                }

                Button {
                    /// cancel the timer before navigate out of the view
                    timer.upstream.connect().cancel()
                } label: {
                    Text("Create Event")
                        .fontWeight(.semibold)
                        .foregroundStyle(.black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(.white, in: .capsule)
                }
                .blurOpacityEffect(initialAnimation)
            }
            .safeAreaPadding(15)
        }
        .onReceive(timer) { _ in
            currentScrollOffset += 0.35
            scrollPosition.scrollTo(x: currentScrollOffset)
        }
        .task {
            try? await Task.sleep(for: .seconds(0.35))

            withAnimation(.smooth(duration: 0.75, extraBounce: 0)) {
                initialAnimation = true
            }

            withAnimation(.smooth(duration: 2.5, extraBounce: 0).delay(0.3)) {
                titleProgress = 2
            }
        }
    }

    @ViewBuilder
    private func ambientBackground() -> some View {
        GeometryReader {
            let size = $0.size

            ZStack {
                ForEach(firstSetCards) { card in
                    Image(card.image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .ignoresSafeArea()
                        .frame(width: size.width, height: size.height)
                        .opacity(activeCard?.id == card.id ? 1 : 0)
                }

                Rectangle()
                    .fill(.black.opacity(0.45))
                    .ignoresSafeArea()
            }
            .compositingGroup()
            .blur(radius: 90, opaque: true)
        }
    }

    @ViewBuilder
    private func carouselCardView(_ card: Card) -> some View {
        GeometryReader {
            let size = $0.size

            Image(card.image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size.width, height: size.height)
                .clipShape(.rect(cornerRadius: 20))
                .shadow(color: .black.opacity(0.4), radius: 10, x: 1, y: 0)
        }
        .frame(width: 220)
        .scrollTransition(.interactive.threshold(.centered), axis: .horizontal) { content, phase in
            content
                .offset(y: phase == .identity ? -10 : 0)
                .rotationEffect(.degrees(phase.value * 5), anchor: .bottom)
        }
    }
}

#Preview {
    InfiniteHorizontalScrollViewDemo()
}

extension View {
    func blurOpacityEffect(_ show: Bool) -> some View {
        blur(radius: show ? 0 : 2)
            .opacity(show ? 1 : 0)
            .scaleEffect(show ? 1 : 0.9)
    }
}
