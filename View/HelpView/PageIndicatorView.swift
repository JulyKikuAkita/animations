//
//  PageIndicatorView.swift
//  animation
import SwiftUI

struct PageIndicatorView: View {
    var activeTint: Color = .primary
    var inactiveTint: Color = .primary.opacity(0.15)
    var opacityEffect: Bool = false
    var clipEdges: Bool = false

    var body: some View {
        GeometryReader {
            /// Entire view size for calculating page indicators
            let width = $0.size.width
            /// ScrollView bounds
            if let scrollViewWidth = $0.bounds(
                of: .scrollView(axis: .horizontal)
            )?.width, scrollViewWidth > 0 {
                let minX = $0.frame(in: .scrollView(axis: .horizontal)).minX
                let totalPages = Int(width / scrollViewWidth)
                /// Progress
                let freeProgress = -minX / scrollViewWidth
                let clippedProgress = min(
                    max(freeProgress, 0.0),
                    CGFloat(totalPages - 1)
                )
                let progress = clipEdges ? clippedProgress : freeProgress
                /// Index
                let activeIndex = Int(progress)
                let nextIndex = Int(progress.rounded(.awayFromZero))

                let indicatorProgress = progress - CGFloat(activeIndex)
                /// Indicator width: current and upcoming
                /// 18 = indicator width of 8 and the hstack spacing of 10
                let currentPageWidth = 18 - (indicatorProgress * 18)
                let nextPageWidth = indicatorProgress * 18

                HStack(spacing: 10) {
                    ForEach(0 ..< totalPages, id: \.self) { index in
                        Capsule()
                            .fill(.clear)
                            .frame(
                                width: 8 + (
                                    activeIndex == index ? currentPageWidth
                                        : nextIndex == index ? nextPageWidth : 0),
                                height: 8
                            )
                            .overlay {
                                ZStack {
                                    Capsule()
                                        .fill(inactiveTint)

                                    Capsule()
                                        .fill(activeTint)
                                        .opacity(opacityEffect ? activeIndex == index ? 1 - indicatorProgress
                                            : nextIndex == index ? indicatorProgress : 0 : 1)
                                }
                            }
                    }
                }
                .frame(width: scrollViewWidth)
                .offset(x: -minX)
            }
        }
        .frame(height: 30)
    }
}
