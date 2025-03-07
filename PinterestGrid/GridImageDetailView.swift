//
//  GridImageDetailView.swift
//  demoApp


import SwiftUI

struct GridImageDetailView: View {
    @Environment(UICoordinatorPinterestGrid.self) private var coordinator
    var body: some View {
        GeometryReader {
            let size = $0.size
            let animateView = coordinator.animateView
            let hideLayer = coordinator.hideLayer

            let anchorX = (coordinator.rect.minX / size.width) > 0.5  ? 1.0 : 0.0
            let scale = size.width / coordinator.rect.width /// scale the padding too
            let rect = coordinator.rect

            /// 15 - Horizontal Padding
            let offsetX = animateView ? (scale < 0.5 ? 15 : -15) * scale : 0
            let offsetY = animateView ? -coordinator.rect.minY * scale : 0

            let detailHeight: CGFloat = rect.height * scale
            let scrollContentHeight: CGFloat = size.height - detailHeight
            if let image = coordinator.animationLayer,
                let post = coordinator.selectedItem {

                if !hideLayer {
                    Image(uiImage: image)
                        .scaleEffect(animateView ? scale : 1, anchor: .init(x: anchorX, y: 0))
                        .offset(x: offsetX, y: offsetY)
                        .offset(y: animateView ? -coordinator.headerOffset : 0)
                        .opacity(animateView ? 0 : 1)
                        .transition(.identity)
                }

                ScrollView(.vertical) {
                    ScrollContent()
                        .safeAreaInset(edge: .top, spacing: 0) {
                            Rectangle()
                                .fill(.clear)
                                .frame(height: detailHeight)
                                .offsetY{ offset in
                                    coordinator.headerOffset = max(min(-offset, detailHeight), 0)
                                }
                        }
                }
                .scrollDisabled(!hideLayer)
                .contentMargins(.top, detailHeight, for: .scrollIndicators)
                .background {
                    Rectangle()
                        .fill(.background)
                        .padding(.top, scrollContentHeight) // or scrollContentHeight ?
                }
                .animation(.easeInOut(duration: 0.3).speed(1.5)) {
                    $0
                        .offset(y: animateView ? 0 : scrollContentHeight)
                        .opacity(animateView ? 1 : 0)
                }

                /// a layer to  handle  animation
                ImageView(post: post)
                    .allowsHitTesting(false)
                    .frame(width: animateView ? size.width : rect.width,
                           height: animateView ? rect.height * scale : rect.height
                    )
                    .clipShape(.rect(cornerRadius:  animateView ? 0 : 10))
                    .overlay(alignment: .top, content: {
                        HeaderActions(post)
                            .offset(y: coordinator.headerOffset)
                            .padding(.top, safeAreaPinterest.top)
                    })
                    .offset(x: animateView ? 0 : rect.minX, y: animateView ? 0 : rect.minY)
                    .offset(y: animateView ? -coordinator.headerOffset : 0)
            }
        }
        .ignoresSafeArea()
    }

    @ViewBuilder
    func ScrollContent() -> some View {
        /// Dummy placeholder, replace with your implementation
        GridImageDetailContentView()
    }

    @ViewBuilder
    func HeaderActions(_ post: PhotoItem) -> some View {
        HStack {
            Spacer(minLength: 0)

            Button(action: {
                coordinator.toggleView(show: false, frame: .zero, post: post)
            }, label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(Color.primary, .bar)
                    .padding(10)
                    .contentShape(.rect)
            })
        }
        .animation(.easeIn(duration: 0.3)) {
            $0
                .opacity(coordinator.hideLayer ? 1: 0)
        }
    }
}

#Preview {
    GridImageDemoView()
}
