//
//  iPodCarousel+iOS26.swift
//  animation
//
//  Created on 5/4/26.
//
// iPod / Cover Flow-style horizontal carousel: cards stay laid out
// side-by-side, the active card faces the viewer, and neighbors rotate
// around their leading/trailing edges so they appear to recede into 3D
// space. A Metal `layerEffect` draws a fading mirror reflection beneath
// every card (see `iPodCarouselReflection.metal`).
//
// Learning points
// ───────────────────────────────────────────────────────────────────────
// 1. `visualEffect` driven by scroll-space `minX`.
//    `proxy.frame(in: .scrollView(axis: .horizontal)).minX / cardWidth`
//    yields a *per-card* progress value where 0 means "I am the active
//    card", positive means "I'm to the right of center", negative means
//    "I'm to the left". The closure runs on every scroll tick, so the
//    rotation/offset numbers track the finger smoothly without driving
//    a `@State` mirror.
//
// 2. Asymmetric anchors flip the rotation pivot.
//    `anchor: cappedProgress < 0 ? .leading : .trailing` is what gives
//    Cover Flow its signature look. A card to the *left* of center
//    rotates around its *leading* (left) edge — so its right edge swings
//    forward. A card to the *right* rotates around its *trailing* edge.
//    Combined with `axis: (0, 1, 0)` (Y-axis spin) this produces the
//    "fanning open" effect.
//
// 3. `anchorZ` lifts the active card off the page.
//    `abs(cappedProgress) * activeElevation` makes the rotation pivot
//    sit *in front of* the layer plane, so the card appears to push
//    forward as it rotates. The slider in the demo binds straight to
//    `activeElevation`, letting you dial the depth in real time.
//
// 4. Counter-translation (`offset(x: -progress * cardWidth/offsetFactor)`).
//    Without this, neighbors would slide off-screen at their natural
//    paging speed. Pulling each card *back toward center* in proportion
//    to its progress keeps the off-axis cards visible — that's the
//    "stack of CDs" peeking from behind the active album.
//
// 5. `viewAligned` + `scrollPosition(id:)` for snap-to-card paging.
//    Unlike AppleTVCarousel (which uses `.paging` for full-page snaps),
//    iPod-style needs to snap to whichever *card* is closest to center,
//    even though cards are narrower than the viewport. `viewAligned` +
//    `scrollTargetLayout()` does that, and the two-way `scrollPosition`
//    binding lets us animate to a specific index from code (the
//    "Go to mid" button).
//
// 6. Centering with `safeAreaPadding`.
//    `safeAreaPadding(.horizontal, (size.width - cardWidth) / 2)` adds
//    half-viewport padding on each side, so the *first* and *last* card
//    can both come to rest at center. This is the iOS-26-friendly
//    replacement for the older "spacer view at index 0" trick.
//
// 7. zIndex follows the active card.
//    `currentIndex > index ? Double(index) : Double(-index)` sorts cards
//    so that whichever side is closer to the active card is drawn on
//    top — the active card itself overrides everything with `1000`.
//    This matters once `anchorZ > 0` lifts cards forward and they would
//    otherwise overlap in the wrong order.
//
// 8. Reflection via `layerEffect` + Metal shader.
//    `layerEffect(ShaderLibrary.carouselCoverFlowReflection(...), maxSampleOffset:)`
//    invokes the `[[stitchable]]` function in `iPodCarouselReflection.metal`.
//    The `maxSampleOffset` tells SwiftUI the shader will paint pixels up
//    to one full card height *below* the original — that extra real
//    estate is what holds the mirror image.
//
// ───────────────────────────────────────────────────────────────────────
// Comparison: AppleTVCarousel vs iPodCarousel
// ───────────────────────────────────────────────────────────────────────
// Both files take a horizontal `ScrollView { LazyHStack { ... } }` and
// drive per-card transforms from `visualEffect` + scroll-space `minX`,
// but the resemblance ends there — they're solving different design
// problems with different SwiftUI primitives.
//
//                       │ AppleTVCarousel        │ iPodCarousel (this)
// ──────────────────────┼────────────────────────┼─────────────────────────
// Visual metaphor       │ Cards stacked on top   │ Cards rotated in 3D,
//                       │ of one another, cross- │ side-by-side ("Cover
//                       │ fading on swipe        │ Flow")
// Scroll snap           │ `.paging` (full page)  │ `.viewAligned` + card-
//                       │                        │  width spacing
// Active-card tracking  │ `onScrollGeometryChange│ `scrollPosition(id:)` —
//                       │  → progress`           │  two-way binding
// Per-card transform    │ Cancel natural layout: │ Keep natural layout +
//                       │ `offset(x: -minX)` so  │ `rotation3DEffect` with
//                       │ all cards stack at     │ flipped anchor + small
//                       │ center, then nudge by  │ counter-translation
//                       │ `movement * progress`  │
// Layering              │ `zIndex(-index)` — a   │ `zIndex` follows the
//                       │ static back-to-front   │ currently active index
//                       │ stack                  │ (dynamic)
// "Reveal" mechanism    │ Opacity crossfade      │ 3D rotation + parallax
//                       │ between adjacent cards │ around active card
// Edge / overflow look  │ `backgroundExtensionEf-│ Mirror reflection drawn
//                       │  fect()` bleeds image  │ by a Metal layerEffect
//                       │ into safe areas        │ shader
// Vertical interactions │ Outer ScrollView pull- │ None — height is fixed
//                       │ down rubber-bands the  │
//                       │ carousel taller        │
// External controls     │ None — pure scroll     │ Slider for elevation +
//                       │                        │ "Go to mid" button via
//                       │                        │ the bound active index
//
// When to reach for which
//   • Hero / "now playing" surface where one big artwork dominates
//     and tapping previews / metadata matter → AppleTVCarousel.
//   • Browse / pick-from-many surface where the user wants to glance
//     across multiple items at once → iPodCarousel.
// ───────────────────────────────────────────────────────────────────────

import SwiftUI

enum CarouselContentStyle: String, CaseIterable, Identifiable {
    case artwork = "Artwork"
    case gradient = "Gradient"
    var id: Self { self }
}

struct iPodCarouselDemoView: View {
    @State private var activeIndex: Int?
    @State private var elevation: CGFloat = 0
    @State private var verticalOffset: CGFloat = 0
    @State private var contentStyle: CarouselContentStyle = .artwork

    private let colors: [Color] = [.indigo, .blue, .red, .yellow, .orange, .pink, .brown, .cyan, .green]

    private var itemCount: Int {
        contentStyle == .artwork ? tvShows.count : colors.count
    }

    var body: some View {
        VStack {
            Picker("Content", selection: $contentStyle) {
                ForEach(CarouselContentStyle.allCases) { style in
                    Text(style.rawValue).tag(style)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            iPodCarousel(
                config: .init(
                    cardWidth: 160,
                    activeElevation: elevation
                ),
                activeIndex: $activeIndex
            ) {
                /// Both branches must resolve to a single `View` type — `if/else`
                /// inside a `@ViewBuilder` closure yields `_ConditionalContent`,
                /// which satisfies the generic. A `switch` on the enum would
                /// scale to more cases.
                if contentStyle == .artwork {
                    ForEach(tvShows) { show in
                        Image(show.artwork)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 220)
                    }
                } else {
                    /// Don't pin an inner height here. The outer
                    /// `iPodCarousel` wraps each subview in
                    /// `.frame(width: cardWidth, height: size.height)`, so an
                    /// inner `.frame(width: 160, height: 200)` would center
                    /// the shape in the 160×220 cell, leaving 10pt gaps top
                    /// and bottom. The Metal shader uses the *cell's* full
                    /// height as `contentHeight`, so those gaps shift the
                    /// reflection out of view. Letting the shape fill the
                    /// cell makes the mirror align correctly.
                    ForEach(colors, id: \.self) { color in
                        RoundedRectangle(cornerRadius: 12)
                            .fill(color.gradient)
                            .frame(width: 160)
                    }
                }
            }
            /// `iPodCarousel` already reserves `cardHeight × 2` (room for
            /// card + reflection) — no `.frame(height:)` needed here.
            /// Rebuild on content switch so the `LazyHStack` doesn't reuse
            /// cells across heterogeneous item counts/sizes.
            .id(contentStyle)

            Group {
                Slider(value: $elevation, in: 0 ... 50)

                Button("Go to mid") {
                    withAnimation(.smooth) {
                        activeIndex = itemCount / 2
                    }
                }
            }
        }
    }
}

struct CoverFlowConfig {
    var cardWidth: CGFloat
    /// Card height used for each cell. The reflection rendered by
    /// `carouselCoverFlowReflection.metal` is the *same height* as the
    /// card, so the carousel reserves `cardHeight × 2` for itself —
    /// callers don't need to set their own `.frame(height:)`.
    var cardHeight: CGFloat = 220
    var rotation: CGFloat = 58
    var offsetFactor: CGFloat = 1.4
    var activeElevation: CGFloat = 0
    /// reflection properties for metal
    var reflectionGap: CGFloat = 0.5
    var reflectionFade: CGFloat = 4
    var reflectionDim: CGFloat = 0.8
}

struct iPodCarousel<Content: View>: View {
    var config: CoverFlowConfig
    @Binding var activeIndex: Int?
    @ViewBuilder var content: Content
    var body: some View {
        GeometryReader {
            let size = $0.size
            // Learning: `activeIndex` is optional because `scrollPosition(id:)`
            // reports `nil` mid-fling. Coalesce to 0 so zIndex math always has
            // a reference point — the binding still receives the real value.
            let currentIndex = activeIndex ?? 0

            ScrollView(.horizontal) {
                // Learning: pin the LazyHStack to the *top* of the
                // GeometryReader so each cell sits flush against the top
                // edge. The lower half is reserved for the reflection
                // pixels emitted by the Metal `layerEffect` (which draw
                // *below* the cell's own frame, up to `maxSampleOffset`).
                LazyHStack(spacing: 0) {
                    // Learning: `Group(subviews:)` (iOS 18+) lets us iterate
                    // a `@ViewBuilder Content` like a collection — required
                    // because we need each child's index for zIndex layering.
                    Group(subviews: content) { collection in
                        ForEach(Array(collection.enumerated()), id: \.offset) { index, subview in
                            // Learning: cards on the *near side* of the active
                            // index get a higher zIndex as you walk away from
                            // center, so neighbors stack toward the active card
                            // instead of away from it (matters once anchorZ
                            // lifts cards forward in 3D).
                            let zIndex = currentIndex > index ? Double(index) : Double(-index)

                            subview
                                // Learning: cell height is `config.cardHeight`,
                                // NOT `size.height`. The carousel's overall
                                // frame is `cardHeight × 2` (see `.frame(...)`
                                // below), and the bottom half is the canvas
                                // the shader paints the mirror reflection
                                // into. If we used `size.height` here the
                                // card would stretch into the reflection
                                // zone and clip the mirror.
                                .frame(width: config.cardWidth, height: config.cardHeight)
                                // Learning: `visualEffect` runs in the render
                                // pass and gets a fresh `proxy` per scroll tick
                                // — perfect for scroll-driven animation without
                                // a `@State` mirror or onChange ladder.
                                .visualEffect { [config] content, proxy in
                                    let values = retrieveCoverFlowLayoutAdjustmentValues(proxy, config: config)
                                    return content
                                        // Learning: `layerEffect` (vs `colorEffect`)
                                        // is needed because the reflection shader
                                        // samples *outside* the source view.
                                        // `maxSampleOffset: proxy.size` reserves
                                        // a card-sized region below for the mirror.
                                        .layerEffect(
                                            ShaderLibrary.carouselCoverFlowReflection(
                                                .float(proxy.size.height),
                                                .float(config.reflectionGap),
                                                .float(config.reflectionFade),
                                                .float(config.reflectionDim)
                                            ),
                                            maxSampleOffset: proxy.size
                                        )
                                        // Learning: Y-axis spin + flipped
                                        // `anchor` (set in the helper below)
                                        // gives the Cover Flow "fan-open" shape.
                                        // `perspective: 1` is a moderate
                                        // foreshortening — closer to 0 = flatter.
                                        .rotation3DEffect(
                                            .init(degrees: values.rotation),
                                            axis: (x: 0, y: 1, z: 0),
                                            anchor: values.anchor,
                                            anchorZ: values.anchorZ,
                                            perspective: 1
                                        )
                                        // Learning: counter-translation pulls
                                        // off-axis cards back toward center so
                                        // they don't slide off the screen at
                                        // their natural paging speed.
                                        .offset(x: values.offset)
                                }
                                // Learning: the active card always wins zIndex
                                // (`1000`) regardless of order — guards against
                                // the rotated edge of a neighbor poking through
                                // the active artwork.
                                .zIndex(currentIndex == index ? 1000 : zIndex)
                        }
                    }
                }
                // Learning: `scrollTargetLayout()` marks this layout as the
                // unit `viewAligned` snaps to. Without it, the scroll view
                // can't tell "card" from "container".
                .scrollTargetLayout()
            }
            // Learning: half-viewport padding on each side so the *first* and
            // *last* card can both come to rest at center. Replaces the older
            // "spacer view at index 0" workaround.
            .safeAreaPadding(.horizontal, (size.width - config.cardWidth) / 2)
            // Learning: two-way binding — scroll updates `activeIndex`, and
            // setting `activeIndex` (inside `withAnimation`) animates the
            // scroll view to that card. `anchor: .center` defines what
            // "active" means.
            .scrollPosition(id: $activeIndex, anchor: .center)
            // Learning: `.viewAligned` snaps to whichever child is closest
            // to center (per `scrollTargetLayout`). `.paging` would snap by
            // viewport width, which is wrong here because cards are 160pt
            // and the viewport is much wider.
            .scrollTargetBehavior(.viewAligned)
        }
        // Learning: reserve `cardHeight × 2` so card + reflection both fit.
        // The reflection is drawn by `layerEffect` *below* each cell — if
        // the parent only gives us `cardHeight`, the mirror gets clipped.
        // Doing this here (instead of asking the caller to set
        // `.frame(height: 440)`) keeps the API self-contained.
        .frame(height: config.cardHeight * 3)
    }
}

private func retrieveCoverFlowLayoutAdjustmentValues(
    _ proxy: GeometryProxy,
    config: CoverFlowConfig
) -> (
    rotation: CGFloat,
    anchor: UnitPoint,
    anchorZ: CGFloat,
    offset: CGFloat
) {
    // Learning: `minX` in `.scrollView(axis: .horizontal)` is each card's
    // distance from the leading edge of the visible viewport, so dividing
    // by `cardWidth` yields a per-card progress: 0 = active, ±1 = one slot
    // away, ±2 = two slots away, etc.
    let minX = proxy.frame(in: .scrollView(axis: .horizontal)).minX
    let progress = minX / config.cardWidth
    // Learning: clamp the *rotation/anchor* progress to [-1, 1] so cards
    // far off-screen don't keep spinning past 90° — but keep the raw
    // `progress` for `offset`, so distant cards still translate.
    let cappedProgress = progress.clamped(to: -1 ... 1)
    let rotation = -cappedProgress * config.rotation
    let offset = -progress * (config.cardWidth / config.offsetFactor)
    // Learning: this is the magic line for Cover Flow — left-of-center
    // cards rotate around their *leading* edge (so their right side
    // swings toward you), right-of-center cards rotate around their
    // *trailing* edge. Symmetric anchors would just spin both sides the
    // same way and the effect collapses.
    let anchor: UnitPoint = cappedProgress < 0 ? .leading : .trailing
    // Learning: `anchorZ` lifts the rotation pivot *toward the camera*,
    // so as a card rotates it also appears to push forward — the active
    // card's slight "lift" comes from this, not from a separate scale.
    let anchorZ = abs(cappedProgress) * config.activeElevation

    return (rotation, anchor, anchorZ, offset)
}

#Preview {
    iPodCarouselDemoView()
}
