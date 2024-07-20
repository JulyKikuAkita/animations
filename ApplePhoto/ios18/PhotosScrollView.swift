//
//  PhotosScrollView.swift
//  demoApp

import SwiftUI

struct PhotosScrollView: View {
    var size: CGSize
    var safeArea: EdgeInsets
    @Environment(SharedData.self) private var sharedData
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
            .scrollTargetLayout()
        }
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.paging)
        /// adding space for indicator
        .safeAreaPadding(.bottom, 15)
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
            alignment: .bottom
        )
        .frame(height: screenHeight - minimizedHeight, alignment: .bottom)
        .overlay(alignment: .bottom) {
            CustomPagingIndicatorView()
        }
    }
    
    @ViewBuilder
    func GridPhotosScrollView() -> some View {
        ScrollView(.vertical) {
            LazyVGrid(columns: Array(repeating: GridItem(spacing: 4), count: 3), spacing: 4) {
                ForEach(0...300, id:\.self) { _ in
                    Rectangle()
                        .fill(.red)
                        .frame(height: 120)
                }
            }
        }
        .defaultScrollAnchor(.bottom) /// make the scroll view start from the bottom
        .scrollDisabled(sharedData.isExpanded)
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
