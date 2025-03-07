//
//  PhotosScrollView.swift
//  demoApp

import SwiftUI

struct PhotosScrollView: View {
    var size: CGSize
    var safeArea: EdgeInsets
    @Environment(SharedData.self) private var sharedData
    /// photo scroll position
    @State private var scrollPosition: ScrollPosition = .init()
    var body: some View {
        let screenHeight = size.height + safeArea.top + safeArea.bottom
        let minimizedHeight = screenHeight * 0.4

        ScrollView(.horizontal) {
            /// default alignment is center
            LazyHStack(alignment: .bottom, spacing: 0) {
                /// Photo Grid Scroll View
                GridPhotosScrollView()
                /// try to use ContainerRelativeFrame as well.
                    .frame(width: size.width)
                    .id(1)

                /// the remaining view, aka the stretchable view only needs to be the remaining height - the minimizedHeight
                /// instead of the full screen height
                Group {
                    StretchableView(.blue)
                        .id(2)
                    StretchableView(.yellow)
                        .id(3)
                    StretchableView(.brown)
                        .id(4)
                }
                .frame(height: screenHeight - minimizedHeight)
            }
            /// adding space for indicator
            .padding(.bottom, safeArea.bottom + 20) /// cause glitch if apply to scroll view instead of its content
            .scrollTargetLayout()
        }
        .scrollClipDisabled()
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.paging)
        /// stay at the bottom when can pull up is true, modifier to scrollView content might cause glitch
        .offset(y: sharedData.canPullUp ? sharedData.photoScrollOffset : 0)
        .scrollPosition(id: .init(get: {
            return sharedData.activePage
        }, set: {
            if let newValue = $0 { sharedData.activePage = newValue }
        }))
        /// Disabling the horizontal scroll interaction when the photo grid is expanded
        .scrollDisabled(sharedData.isExpanded)
        .frame(height: screenHeight)
        /// increasing the scrollView height based on progress
        .frame(height: screenHeight - (minimizedHeight - (minimizedHeight * sharedData.progress)),
               alignment: .bottom)
        .overlay(alignment: .bottom) {
            CustomPagingIndicatorView {
                Task {
                    /// check if photo view is scrolled
                    if sharedData.photoScrollOffset != 0 {
                        /// if so, reset scroll position
                        withAnimation(.easeInOut(duration: 0.15)) {
                            scrollPosition.scrollTo(edge: .bottom)
                        }

                        try? await Task.sleep(for: .seconds(0.13))
                    }

                    /// minimizing expand view
                    withAnimation(.easeInOut(duration: 0.25)) {
                        sharedData.progress = 0
                        sharedData.isExpanded = false

                    }
                }
            }
        }
    }

    @ViewBuilder
    func GridPhotosScrollView() -> some View {
        ScrollView(.vertical) {
            LazyVGrid(columns: Array(repeating: GridItem(spacing: 4), count: 3), spacing: 4) {
                ForEach(0...300, id:\.self) { _ in
                    Rectangle()
                        .fill(.pink.gradient.opacity(0.5))
                        .frame(height: 120)
                }
            }
            .offset(y: sharedData.progress * -(safeArea.bottom + 20))
            .scrollTargetLayout()
        }
        .defaultScrollAnchor(.bottom) /// make the scroll view start from the bottom
        .scrollDisabled(!sharedData.isExpanded)
        .scrollPosition($scrollPosition)
        .scrollClipDisabled()
        .onScrollGeometryChange(for: CGFloat.self, of: {
            /// This will be zero when content is placed at the bottom
            $0.contentOffset.y - $0.contentSize.height + $0.containerSize.height
        }, action: { oldValue, newValue in
            sharedData.photoScrollOffset = newValue
        })
    }

    /// Stretchable Paging Views
    @ViewBuilder
    func StretchableView(_ color: Color) -> some View {
        GeometryReader {
            let minY = $0.frame(in: .scrollView(axis: .vertical)).minY
            let size = $0.size

            Rectangle()
                .fill(color)
                .frame(width: size.width, height: size.height + (minY > 0 ? minY : 0)) /// make the view stretchable
                .offset(y: (minY > 0 ? -minY : 0)) /// make the view stretchable
        }
        .frame(width: size.width)
    }
}

#Preview {
    PhotoAppIOS18DemoView()
}
