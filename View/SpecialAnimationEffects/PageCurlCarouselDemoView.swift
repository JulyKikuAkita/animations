//
//  PageCurlCarouselDemoView.swift
//  animation
//
//  Created on 12/25/25.
// with Metal shader
// Using Scrollview to achieve the page curl effect for the carousel with
// 1. covert scrollView to paging scroll view (in which each element has the same size)
// 2. apply visualEffect Modifier to each page view to achieve zStack-like layout
// 3. use onScrollGeometryChange to calculate current progress for curl effect
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
