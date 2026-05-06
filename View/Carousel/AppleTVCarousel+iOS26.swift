//
//  AppleTVCarousel+iOS26.swift
//  animation
//
//  Created on 3/14/26.
//
// Apple TV-style hero carousel: paged horizontal scroll where each card sits
// on top of the next, the active card crossfades while the user swipes, and
// the whole carousel rubber-bands taller as the outer ScrollView is pulled
// down (mirroring tvOS / Apple TV app).
//
// Learning points
// ───────────────────────────────────────────────────────────────────────
// 1. `.backgroundExtensionEffect()` (iOS 26).
//    Extends the image's edge pixels into the nearest safe area with a soft
//    blur, so the artwork "bleeds" past the screen bounds without the author
//    drawing a separate background. Applied twice here:
//      • on the outer ScrollView so the active card fills the status-bar
//        / home-indicator regions, and
//      • on each card image so its edges also extend through the
//        `safeAreaPadding(.horizontal, movement + 10)` gutter that exists
//        only to give `visualEffect` room to translate the card.
//
// 2. Faking a ZStack with a paging horizontal `LazyHStack`.
//    A real `ScrollView` lays cards out side-by-side, but `.zIndex(-index)`
//    plus a per-card `visualEffect { content.offset(x: -minX) }` cancels
//    each card's natural horizontal placement so every card renders at the
//    same on-screen position. The result behaves like a `ZStack` while
//    still getting paging, hit-testing, and scroll-state for free.
//
// 3. Scroll-driven parallax via `visualEffect` + scroll-space frame.
//    Reading `proxy.frame(in: .scrollView(axis: .horizontal)).minX` gives a
//    per-card position relative to the viewport. Normalising it to
//    `[-1, 1]` (`movementProgress`) and multiplying by `movement` shifts the
//    card horizontally as the user drags — that's the subtle "card slides
//    while the next one reveals" effect.
//
// 4. `onScrollGeometryChange` → progress (iOS 18+).
//    `contentOffset.x + contentInsets.leading` divided by page width yields
//    a continuous `progress` (0, 1, 2, …). The integer part is the active
//    index; the fractional part drives `opacity = progress - index`, giving
//    a clean crossfade between the current and next card without a Timer
//    or onChange ladder.
//
// 5. Vertical stretch / rubber-band on pull-down.
//    The outer ScrollView reports its own `contentOffset.y + contentInsets.top`
//    via `onScrollGeometryChange`. When that value is negative (overscroll
//    at the top), we set `verticalOffset = -newValue` and apply
//    `.frame(height: 500 + verticalOffset).offset(y: -verticalOffset)` —
//    the carousel grows downward while staying anchored at its top edge.
//
// 6. Hiding overlay text mid-swipe with `onScrollPhaseChange`.
//    `scrollPhase != .interacting` keeps the title/buttons visible only
//    when the user is *not* actively dragging. Wrapping the opacity change
//    in `.animation(isActive ? .linear(...) : .none) { content in ... }`
//    means only the active card animates — the inactive ones snap, which
//    avoids flicker as cards swap roles.
// ───────────────────────────────────────────────────────────────────────

import SwiftUI

@available(iOS 26.0, *)
struct AppleTVCarouselDemoView: View {
    @State private var activeIndex: Int = 0
    // Learning: track the live ScrollPhase so we can hide overlay text
    // *only* while the user is actively dragging — not while the scroll
    // view is decelerating or idle.
    @State private var scrollPhase: ScrollPhase = .idle
    // Learning: positive when the outer ScrollView is overscrolled at the
    // top. We use it to grow the carousel height *and* offset it up by
    // the same amount, anchoring its top edge in place.
    @State private var verticalOffset: CGFloat = 0
    var body: some View {
        ScrollView(.vertical) {
            VStack {
                AppleTVCarousel {
                    ForEach(tvShows) { show in
                        Image(show.artwork)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .overlay(alignment: .bottom) {
                                bottomContent(show)
                            }
                    }
                } scrollProgress: { progress in
                    // Learning: `progress.rounded()` snaps the continuous
                    // 0…N-1 value to the nearest whole index; `min(...)`
                    // guards against overshoot at the trailing edge.
                    activeIndex = min(Int(progress.rounded()), tvShows.count - 1)
                }
                .onScrollPhaseChange { _, newPhase in
                    scrollPhase = newPhase
                }
                // Learning: grow the height *and* shift up by the same
                // amount → the carousel's top edge stays put while the
                // bottom expands. That's the rubber-band stretch.
                .frame(height: 500 + verticalOffset)
                .offset(y: -verticalOffset)
            }
        }
        // Learning: `contentOffset.y + contentInsets.top` is 0 at rest,
        // negative on overscroll-at-top, positive on scroll-down. Clamping
        // `max(-newValue, 0)` keeps `verticalOffset` non-negative — we
        // only stretch on pull-down, never compress on scroll-up.
        .onScrollGeometryChange(for: CGFloat.self, of: {
            $0.contentOffset.y + $0.contentInsets.top
        }, action: { _, newValue in
            verticalOffset = max(-newValue, 0)
        })
        // Learning: applied to the *outer* ScrollView so the active card
        // bleeds past status bar / home indicator into the safe areas.
        .backgroundExtensionEffect()
    }

    func bottomContent(_ show: TVShow) -> some View {
        // Learning: identity check via `id`, not index, because each card
        // builds independently and doesn't know its own index.
        let isActive: Bool = tvShows[activeIndex].id == show.id
        return VStack(spacing: 0) {
            Text(show.title)
                .font(.system(size: 50, weight: .black))

            Text(show.subtitle)
                .font(.system(size: 25, weight: .black))

            Text(show.content)
                .font(.callout)
                .fontWeight(.medium)
                .padding(.top, 10)

            /// Dummy buttons
            HStack(spacing: 10) {
                Button {} label: {
                    HStack(spacing: 10) {
                        Image(systemName: "play.fill")
                        Text("Play")
                    }
                    .frame(width: 150, height: 45)
                    .foregroundStyle(.black)
                    .background(.white, in: .capsule)
                }

                Button {} label: {
                    HStack(spacing: 10) {
                        Image(systemName: "plus")
                    }
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                    .frame(width: 45, height: 45)
                    .background(.white.tertiary, in: .circle)
                }
            }
            .padding(.top, 15)
        }
        .foregroundStyle(.white)
        // Learning: `compositingGroup()` flattens this VStack into a
        // single layer first, so the `.opacity(...)` below fades it
        // uniformly instead of compounding per-child alpha.
        .compositingGroup()
        .padding(.bottom, 35)
        // Learning: only the *active* card gets an animated opacity
        // change — inactive cards snap. Animating inactive cards causes
        // visible flicker as roles swap during a swipe.
        .animation(isActive ? .linear(duration: 0.18) : .none) { content in
            content
                .opacity(scrollPhase != .interacting ? 1 : 0)
        }
        // Learning: outer opacity is the identity gate (only the active
        // card is ever non-transparent); inner opacity is the
        // interactive-state gate (hidden mid-drag). Two separate
        // concerns, two separate modifiers.
        .opacity(isActive ? 1 : 0)
    }
}

@available(iOS 26.0, *)
struct AppleTVCarousel<Content: View>: View {
    // Learning: how far each card slides during a swipe. Larger values
    // = more parallax. Needs matching `safeAreaPadding` below so cards
    // don't run out of room to translate into.
    var movement: CGFloat = 60
    @ViewBuilder var content: Content
    var scrollProgress: (CGFloat) -> Void
    @State private var progress: CGFloat = 0
    var body: some View {
        GeometryReader {
            let size = $0.size

            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    Group(subviews: content) { collection in
                        ForEach(Array(collection.enumerated()), id: \.offset) { index, subview in
                            // Learning: the last card has nothing to fade
                            // *into* (it's the bottom of the stack), so
                            // pin its opacity to 0 — never fades out.
                            let isLast: Bool = index == collection.count - 1
                            // Learning: per-card opacity is the *fractional*
                            // distance from the active index. Card N is
                            // fully visible when progress=N, fully faded
                            // when progress=N+1, linearly between.
                            let opacity = isLast ? 0 : max(min(progress - CGFloat(index), 1), 0)
                            ZStack {
                                subview
                                    .frame(width: size.width, height: size.height)
                                    .clipped()
                                    // Learning: a *second* extension
                                    // effect on each card so its image
                                    // bleeds through the horizontal
                                    // gutter created by `safeAreaPadding`
                                    // (which exists only to give the
                                    // visualEffect room to translate).
                                    .backgroundExtensionEffect()
                                    .safeAreaPadding(.horizontal, movement + 10)
                                    .mask {
                                        // Learning: mask with a Rectangle
                                        // that ignores safe areas → keeps
                                        // the horizontal bleed but clips
                                        // any vertical bleed that the
                                        // extension effect introduces.
                                        Rectangle()
                                            .ignoresSafeArea()
                                    }
                            }
                            .frame(width: size.width, height: size.height)
                            // Learning: flatten before opacity so the
                            // crossfade composites the whole card as one
                            // layer (no double-fading the image + overlay).
                            .compositingGroup()
                            .opacity(1 - opacity)
                            // Learning: the ZStack illusion. `offset(x: -minX)`
                            // cancels each card's natural position so all
                            // cards land at the same on-screen spot; the
                            // second `.offset` then nudges them by
                            // `movement * progress` for the parallax slide.
                            .visualEffect { [movement] content, proxy in
                                let minX = proxy.frame(in: .scrollView(axis: .horizontal)).minX
                                // Learning: clamp to [-1, 1] so distant
                                // cards don't translate further and
                                // further off-screen.
                                let movementProgress = (minX / size.width).clamped(to: -1 ... 1)
                                return content
                                    .offset(x: -minX)
                                    .offset(x: movement * movementProgress)
                            }
                            // Learning: paint earlier cards *on top*.
                            // Combined with the opacity fade above, the
                            // top card is always the most visible — when
                            // it fades out, the next one is revealed
                            // underneath like a deck of cards.
                            .zIndex(Double(-index))
                        }
                    }
                }
            }
            // Learning: `.paging` snaps by *viewport width* (each card
            // already fills the viewport), so unlike iPodCarousel we
            // don't need `scrollTargetLayout()` here.
            .scrollTargetBehavior(.paging)
            .scrollIndicators(.hidden)
            // Learning: continuous progress = (offset + leading inset) /
            // page width. Integer part is index; fractional part drives
            // the per-card opacity above.
            .onScrollGeometryChange(for: CGFloat.self) {
                $0.contentOffset.x + $0.contentInsets.leading
            } action: { _, newValue in
                progress = max(newValue / size.width, 0)
                scrollProgress(progress)
            }
        }
    }
}

@available(iOS 26.0, *)
#Preview {
    AppleTVCarouselDemoView()
}
