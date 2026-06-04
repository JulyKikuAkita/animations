//
//  PageCurlCarouselDemoView.swift
//  animation
//
//  Created on 12/25/25.
//
//  Learning point
//  ──────────────
//  iBooks-style page-curl carousel: a horizontal pager where the
//  currently-leaving page literally CURLS off to the right
//  (revealing a back face and an underneath shadow) as the user
//  swipes — driven by the `pageCurlEffect` Metal shader in
//  `[[PageCurlEffect]]`.
//
//  The architectural trick: ScrollView-as-pager with shader-as-effect
//  ──────────────────────────────────────────────────────────────────
//  Three steps fuse a normal `ScrollView(.horizontal)` into a
//  page-turning experience:
//
//    1. **`scrollTargetBehavior(.paging)`** — turns horizontal
//       drags into discrete page snaps. Each "page" is a child of
//       fixed `size = pageSize(geometry.size)`.
//    2. **`visualEffect { content, proxy in content.offset(x: -minX) }`** —
//       per-page modifier that COUNTERS the scroll offset, pinning
//       every page in place visually. Without this, pages would
//       slide normally; with it, every page sits at the same
//       on-screen position and the SHADER does the visual work.
//    3. **`zIndex(Double(-index))`** — keeps stacking order
//       correct: page 0 on top, page 1 below it, etc. As page 0
//       curls away, page 1 is revealed underneath rather than
//       sliding sideways.
//
//  Without these three, the ScrollView would behave like a normal
//  pager. With them, the user is "scrubbing" a 1D progress value
//  the curl shader interprets as drag distance.
//
//  How `scrollProgress` maps to the shader
//  ───────────────────────────────────────
//  `scrollProgress = (contentOffsetX + leadingInset) / pageWidth` —
//  a continuous value where each whole number = a fully-curled page.
//  Inside `PageCurlItemView`, only the page whose `index..index+1`
//  range contains `scrollProgress` updates its `dragOffset`:
//
//      let progress = newValue - range.lowerBound        // 0 → 1
//      dragOffset = progress * (size.width + curlRadius * 2)
//
//  → drives the shader's `drag` parameter from 0 (not curled) to
//  full-width-plus-curl-radius (page completely off the right).
//
//  Why `Group(subviews: content) { collection in ... }` (iOS 18+)
//  ──────────────────────────────────────────────────────────────
//  Lets the parent introspect the children declared in the trailing
//  closure as a `SubviewsCollection`. This is what allows `enumerate
//  + index` for the `zIndex` and per-page wiring without forcing
//  callers to use `ForEach` themselves.
//
//  Why the page size needs explicit aspect-ratio scaling
//  ─────────────────────────────────────────────────────
//  `pageSize(_ viewSize:)` constrains the carousel to a fixed
//  411×800 aspect ratio (mimicking iPhone Pro book pages). Without
//  this, pages would stretch on landscape or iPad — the curl effect
//  looks visually wrong on extreme aspect ratios.
//
//  Key APIs
//  ────────
//  • `.layerEffect(ShaderLibrary.pageCurlEffect(...), maxSampleOffset:)`
//    — invoke the Metal shader per page.
//  • `.visualEffect { content, proxy in ... }` — read scroll-frame
//    geometry without GeometryReader.
//  • `.scrollTargetBehavior(.paging)` — discrete page snaps.
//  • `.onScrollGeometryChange(for:of:action:)` — drive shader
//    parameters from live scroll offset.
//  • `Group(subviews: content) { collection in ... }` — iOS 18
//    declarative subview introspection.
//
//  How to apply
//  ────────────
//  Use whenever a horizontal carousel needs more than a slide —
//  reading apps, photo carousels, story books, hero feature
//  reveals. The "ScrollView as progress source, shader as effect"
//  pattern generalises to any scroll-driven custom transition.
//
//  See also
//  ────────
//  • PageCurlEffect.metal — the shader doing all the heavy lifting.
//  • View/Sheet/iOS26ResizingSheet.swift — same idea (drive a
//    custom effect from scroll) applied to a sheet's height.
//

import SwiftUI

struct PageCurlCarouselConfig {
    var curlRadius: CGFloat
    var curlShadow: CGFloat = 0.3
    var underneathShadow: CGFloat = 0.2
    var roundedRectangle: Self.RoundedRectangle = .init()
    var curlCenter: CGPoint = .init(x: 1, y: 0.5)

    struct RoundedRectangle {
        var topLeft: CGFloat = 0
        var topRight: CGFloat = 0
        var bottomLeft: CGFloat = 0
        var bottomRight: CGFloat = 0
    }
}

struct PageCurlCarouselDemoView: View {
    var body: some View {
        GeometryReader {
            let viewSize = $0.size
            let pageSize = pageSize(viewSize)

            PageCurlCarousel(config: config) { _ in
                Rectangle()
                    .fill(.red)

                Rectangle()
                    .fill(.indigo)

                Rectangle()
                    .fill(.blue)

                Rectangle()
                    .fill(.yellow)
            }
            .frame(width: pageSize.width, height: pageSize.height)
        }
        .padding(30)
    }

    func pageSize(_ viewSize: CGSize) -> CGSize {
        let actualSize = CGSize(width: 411, height: 800)
        /// get the aspect ratios
        let widthFactor = viewSize.width / actualSize.width
        let heightFactor = viewSize.height / actualSize.height
        let aspectScale = min(widthFactor, heightFactor)

        return CGSize(
            width: actualSize.width * aspectScale,
            height: actualSize.height * aspectScale
        )
    }

    var config: PageCurlCarouselConfig {
        .init(curlRadius: 80
        )
    }
}

struct PageCurlCarousel<Content: View>: View {
    var config: PageCurlCarouselConfig
    @ViewBuilder var content: (CGSize) -> Content
    /// Scroll Progress
    @State private var scrollProgress: CGFloat = 0
    var body: some View {
        GeometryReader {
            let size = $0.size

            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    Group(subviews: content(size)) { collection in
                        ForEach(collection.indices, id: \.self) { index in
                            PageCurlItemView(
                                index: index,
                                size: size,
                                config: config,
                                scrollProgress: scrollProgress
                            ) {
                                collection[index]
                                    .frame(width: size.width, height: size.height)
                                    .compositingGroup()
                            }
                            .clipShape(
                                UnevenRoundedRectangle(
                                    topLeadingRadius: config.roundedRectangle.topLeft,
                                    bottomLeadingRadius: config.roundedRectangle.bottomLeft,
                                    bottomTrailingRadius: config.roundedRectangle.bottomRight,
                                    topTrailingRadius: config.roundedRectangle.topRight
                                )
                            )
                            .visualEffect { content, proxy in
                                let minX = proxy.frame(in: .scrollView(axis: .horizontal)).minX
                                return content
                                    .offset(x: -minX)
                            }
                            /// maintain the same zIndex order
                            .zIndex(Double(-index))
                        }
                    }
                }
            }
            .scrollTargetBehavior(.paging)
            .onScrollGeometryChange(for: CGFloat.self) {
                $0.contentOffset.x + $0.contentInsets.leading
            } action: { _, newValue in
                let progress = newValue / size.width
                scrollProgress = progress
            }
        }
    }
}

private struct PageCurlItemView<Content: View>: View {
    var index: Int
    var size: CGSize
    var config: PageCurlCarouselConfig
    var scrollProgress: CGFloat
    @ViewBuilder var content: Content
    /// View Properties
    @State private var dragOffset: CGFloat = 0
    var body: some View {
        content
            .layerEffect(
                ShaderLibrary.pageCurlEffect(
                    .float(dragOffset),
                    .float2(size.width, size.height),
                    .float4(
                        config.roundedRectangle.topLeft,
                        config.roundedRectangle.topRight,
                        config.roundedRectangle.bottomLeft,
                        config.roundedRectangle.bottomRight
                    ),
                    .float2(
                        size.width * config.curlCenter.x,
                        size.height * config.curlCenter.y
                    ),
                    .float(config.curlRadius),
                    .float(config.curlShadow),
                    .float(config.underneathShadow)
                ),
                maxSampleOffset: size
            )
            .onChange(of: scrollProgress) { _, newValue in
                let range = CGFloat(index) ... CGFloat(index + 1)
                if range.contains(newValue) {
                    let progress = newValue - range.lowerBound
                    dragOffset = progress * (size.width + (config.curlRadius * 2))
                }
            }
    }
}

#Preview {
    PageCurlCarouselDemoView()
}
