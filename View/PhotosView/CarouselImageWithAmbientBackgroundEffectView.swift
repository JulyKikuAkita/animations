//
//  CarouselImageWithAmbientBackgroundEffectView.swift
//  animation
//
//  Standalone demo (not wired into the app's demo browser; preview-only).
//
//  TODO: Cleanup
//        Top-level `let images = firstSetCards` below leaks into
//        module scope — every other file in the target sees a global
//        named `images`. Move it inside `ImageWithAmbientBackgroundDemoView`
//        as a stored property, or rename to a file-private constant
//        (`private let images = ...`).
//
//  Learning point
//  ──────────────
//  Apple Music–style "ambient" carousel: a horizontally-paged image
//  carousel sits over a heavily-blurred copy of the SAME images,
//  cross-fading the background as the user pages. Two scroll-geometry
//  subscriptions feed two distinct effects:
//    • `topInset` + vertical `scrollOffsetY` — pulls the ambient
//      backdrop UP so it covers the area behind the header on scroll.
//    • Horizontal `scrollProgressX` (0...count-1) — drives per-image
//      `opacity(index - scrollProgressX)` on the stacked backdrop,
//      producing a continuous cross-fade rather than a hard cut.
//
//  Key APIs
//  ────────
//  • `.onScrollGeometryChange(for:_:action:)` — iOS 18+. Used twice
//    with two different shapes (ScrollGeometry vs. CGFloat): once
//    on the outer vertical ScrollView, once on the inner paging
//    carousel.
//  • `.scrollTargetBehavior(.viewAligned(limitBehavior: .always))` +
//    `.scrollTargetLayout()` — snaps the carousel one image at a
//    time.
//  • `.containerRelativeFrame(.horizontal)` — sizes each image to
//    fill the carousel viewport.
//  • `.compositingGroup() + .blur(radius:opaque:) + .mask(...)` — the
//    ambient blur stack. `opaque: true` is critical; without it the
//    blur leaks edge pixels.
//  • `.scaleEffect(y: -1)` on the background gradient — vertical
//    flip for the dark→light bottom fade.
//
//  How to apply
//  ────────────
//  Use when you want carousel content to colour the surrounding
//  chrome. Cost is rendering N stacked + blurred copies — fine for
//  ~5 cards, watch for jank with large sets. The inline
//  "better to use a low resolution image here" note is the right
//  instinct: feed a downscaled variant to `backdropCarouselView`.
//
//  See also
//  ────────
//  • View/Carousel/* — non-ambient carousel patterns.
//  • PlayStationApp/View — uses similar ambient-blur staging.
//
import SwiftUI

// any image model has id, image
let images = firstSetCards
struct ImageWithAmbientBackgroundDemoView: View {
    /// View properties
    @State private var topInset: CGFloat = 0
    @State private var scrollOffsetY: CGFloat = 0
    @State private var scrollProgressX: CGFloat = 0
    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 15) {
                headerView()

                carouselView()
                    /// placing at the lowest level of all views
                    .zIndex(-1)
            }
        }
        .safeAreaPadding(15)
        .background {
            Rectangle()
                .fill(.black.gradient)
                /// flipping by vertical axis
                .scaleEffect(y: -1)
                .ignoresSafeArea()
        }
        /// calculate offset of header for gradient background to cover the top area
        .onScrollGeometryChange(for: ScrollGeometry.self) {
            $0
        } action: { _, newValue in
            /// 100: height of the header view + space (using geometryReader, minY value)
            topInset = newValue.contentInsets.top + 100
            scrollOffsetY = newValue.contentOffset.y + newValue.contentInsets.top
        }
    }

    func headerView() -> some View {
        HStack {
            Image(systemName: "xbox.logo")
                .font(.system(size: 35))

            VStack(alignment: .leading, spacing: 6) {
                Text("Xbox")
                    .font(.callout)
                    .fontWeight(.semibold)

                HStack(spacing: 6) {
                    Image(systemName: "z.circle.fill")

                    Text("87,777")
                        .font(.caption)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "square.and.arrow.up.circle.fill")
                .font(.largeTitle)
                .foregroundStyle(.white, .fill)

            Image(systemName: "bell.circle.fill")
                .font(.largeTitle)
                .foregroundStyle(.white, .fill)
        }
        .padding(.bottom, 15)
    }

    func carouselView() -> some View {
        let spacing: CGFloat = 10
        return ScrollView(.horizontal) {
            LazyHStack(spacing: spacing) {
                ForEach(images) { model in
                    Image(model.image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .containerRelativeFrame(.horizontal)
                        .frame(height: 380)
                        .clipShape(.rect(cornerRadius: 10))
                        .shadow(color: .black.opacity(0.4), radius: 5, x: 5, y: 5)
                }
            }
            .scrollTargetLayout()
        }
        .frame(height: 380)
        .background(backdropCarouselView())
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
        /// match background image with the current scroll image
        .onScrollGeometryChange(for: CGFloat.self) {
            let offsetX = $0.contentOffset.x + $0.contentInsets.leading
            let width = $0.containerSize.width + spacing

            return offsetX / width
        } action: { _, newValue in
            let maxValue = CGFloat(images.count - 1)
            scrollProgressX = min(max(newValue, 0), maxValue)
        }
    }

    @ViewBuilder
    func backdropCarouselView() -> some View {
        GeometryReader {
            let size = $0.size

            ZStack {
                ForEach(images.reversed()) { model in
                    let index = CGFloat(images.firstIndex(where: { $0.id == model.id }) ?? 0) + 1
                    /// better to use a low resolution image here
                    Image(model.image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size.width, height: size.height)
                        .clipped()
                        .opacity(index - scrollProgressX)
                }
            }
            .compositingGroup()
            .blur(radius: 30, opaque: true)
            .overlay {
                Rectangle()
                    .fill(.black.opacity(0.35))
            }
            .mask {
                Rectangle()
                    .fill(.linearGradient(
                        colors: [
                            .black,
                            .black,
                            .black,
                            .black,
                            .black.opacity(0.5),
                            .clear,
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ))
            }
        }
        /// so that the view can occupies the full available width
        .containerRelativeFrame(.horizontal)
        /// extending to the bottom side for better progressive effect
        .padding(.bottom, -60)
        .padding(.top, -topInset)
        .offset(y: scrollOffsetY < 0 ? -scrollOffsetY : 0)
    }
}

#Preview {
    ImageWithAmbientBackgroundDemoView()
        .preferredColorScheme(.dark)
}
