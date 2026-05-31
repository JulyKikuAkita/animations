//
//  CardCarouselWithScrollTransitionsAPI.swift
//  animation
//
//  Standalone demo (not wired into the app's demo browser; preview-only).
//  iOS 18+ only — `.scrollTransition(.interactive)` with phase-driven
//  effects is the gating API.
//
//  Learning point
//  ──────────────
//  Catalog of three carousel "feels" built entirely from one tool —
//  `.scrollTransition(.interactive) { content, phase in ... }`. The
//  phase value (`.identity` / `.topLeading` / `.bottomTrailing`)
//  exposes a continuous 0...1 you can drive *anything* with: opacity,
//  rotation, blur, scale, offset. Read this file as three worked
//  examples of the same API knob:
//
//    • `ParallaxCarousel18View`  — phase → vertical offset →
//      classic horizontal-parallax look.
//    • `ScaleCarousel18View`     — phase → blur radius + scale →
//      "in-focus card" effect; flanking cards blurred and shrunk.
//    • `CircularCarousel18View`  — phase → blur + scale + rotation +
//      offset combined → cards orbit around an arc as they enter
//      and leave.
//    • `StackCardCarouselView`   — uses `zIndex(1.0 - blur)` plus
//      negative `offset` so successive cards stack ON TOP of the
//      active one instead of sliding past — pairs with
//      `.scrollClipDisabled()` so cards can render outside the
//      ScrollView's frame.
//
//  Key APIs
//  ────────
//  • `.scrollTransition(.interactive)` — iOS 18+. Phase-driven
//    transition modifier; runs once per visible item per scroll tick.
//  • `.scrollClipDisabled()` — required for `StackCardCarouselView`
//    so off-frame cards still render.
//  • `.scrollTargetLayout()` + `.scrollTargetBehavior(.viewAligned)` —
//    snap-per-item.
//  • Phase `.value` — the ±1 progress you multiply through.
//
//  How to apply
//  ────────────
//  Pick the example whose feel matches yours, then strip the others.
//  These demos deliberately keep the math obvious; in production
//  you'd extract the phase→effect math into a `ViewModifier`.
//
//  See also
//  ────────
//  • CardCarouselView.swift — pre-iOS 18 way to do the same thing
//    using manual `minX` reduction math.
//  • CircularCarouselSliderView.swift — `visualEffect`-based
//    circular carousel for iOS 17.
//  • ImageCarouselView.swift — extracts a similar pattern into a
//    reusable `CustomCarousel<Content, Data>` generic.
//
import SwiftUI

struct CardCarouselWithScrollTransitionsAPIView: View {
    var body: some View {
        NavigationStack {
            GeometryReader {
                let size = $0.size
                parallaxCarousel18View(size: size)
            }
        }
        .safeAreaPadding(.horizontal, 15)
        .frame(height: 330)
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
                        .frame(width: 220, height: size.height)
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

    /// Demo blur + scale scroll View
    @ViewBuilder
    func scaleCarousel18View(size: CGSize) -> some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 10) {
                ForEach(firstSetCards) { card in

                    Image(card.image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 220, height: size.height)
                        .clipShape(.rect(cornerRadius: 25))
                        .shadow(color: .black.opacity(0.25), radius: 8, x: 5, y: 10)
                        .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                            content
                                .blur(radius: phase == .identity ? 0 : 2, opaque: false)
                                .scaleEffect(phase == .identity ? 1 : 0.9, anchor: .bottom)
                        }
                }
            }
            .scrollTargetLayout()
        }
        .scrollClipDisabled()
        .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
        .scrollIndicators(.hidden)
    }

    /// Demo blur + scale scroll View
    @ViewBuilder
    func circularCarousel18View(size: CGSize) -> some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 10) {
                ForEach(firstSetCards) { card in

                    Image(card.image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 220, height: size.height)
                        .clipShape(.rect(cornerRadius: 25))
                        .shadow(color: .black.opacity(0.25), radius: 8, x: 5, y: 10)
                        .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                            content
                                .blur(radius: phase == .identity ? 0 : 2, opaque: false)
                                .scaleEffect(phase == .identity ? 1 : 0.9, anchor: .bottom)
                                .offset(y: phase == .identity ? 0 : 35)
                                .rotationEffect(.init(degrees: phase == .identity ? 0 : phase.value * 15),
                                                anchor: .bottom)
                        }
                }
            }
            .scrollTargetLayout()
        }
        .scrollClipDisabled()
        .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
        .safeAreaPadding(.horizontal, (size.width - 220) / 2)
        .scrollIndicators(.hidden)
    }
}

#Preview {
    CardCarouselWithScrollTransitionsAPIView()
    StackCardCarouselView()
}

/// Stack card carousel
struct StackCardCarouselView: View {
    var body: some View {
        NavigationStack {
            GeometryReader {
                let size = $0.size
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 10) {
                        ForEach(firstSetCards) { card in
                            let index = Double(firstSetCards.firstIndex(where: { $0.id == card.id }) ?? 0)

                            GeometryReader {
                                let minX = $0.frame(in: .scrollView(axis: .horizontal)).minX

                                Image(card.image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 220, height: size.height)
                                    .clipShape(.rect(cornerRadius: 25))
                                    .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                                        content
                                            .blur(radius: phase == .identity ? 0 : 2, opaque: false)
                                            .scaleEffect(phase == .identity ? 1 : 0.9, anchor: .bottom)
                                            .offset(y: phase == .identity ? 0 : -10)
                                            .rotationEffect(.init(degrees: phase == .identity ? 0 : phase.value * 5),
                                                            anchor: .bottomTrailing)
                                            .offset(x: minX < 0 ? minX / 2 : -minX)
                                    }
                            }
                            .frame(width: 220)
                            .zIndex(-index)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollClipDisabled()
                .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
                .safeAreaPadding(.horizontal, (size.width - 220) / 2)
            }
        }
        .safeAreaPadding(.horizontal, 15)
        .frame(height: 330)
    }
}
