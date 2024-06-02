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
            let hideView = coordinator.hideRootView
            let hideLayer = coordinator.hideLayer
            
            let anchorX = (coordinator.rect.minX / size.width) > 0.5  ? 1.0 : 0.0
            let scale = size.width / coordinator.rect.width /// scale the padding too
            let rect = coordinator.rect
            
            /// 15 - Horizontal Padding
            let offsetX = animateView ? (scale < 0.5 ? 15 : -15) * scale : 0
            let offsetY = animateView ? -coordinator.rect.minY * scale : 0
            
            if let image = coordinator.animationLayer,
                let post = coordinator.selectedItem {
                Image(uiImage: image)
                    .scaleEffect(animateView ? scale : 1, anchor: .init(x: anchorX, y: 0))
                    .offset(x: offsetX, y: offsetY)
                    .opacity(animateView ? 0 : 1)
                    .onTapGesture {
                        coordinator.animationLayer = nil
                        coordinator.hideRootView = false
                        coordinator.animateView = false
                    }
                
                ScrollView(.vertical) {
                    // TODO: 11:39 https://www.youtube.com/watch?v=fBCu7rM5Vkw&list=PLimqJDzPI-H97JcePxWNwBXJoGS-Ro3a-&index=105
                    
                }
                
                /// a layer to  handle  animation
                ImageView(post: post)
                    .allowsHitTesting(false)
                    .frame(width: animateView ? size.width : rect.width,
                           height: animateView ? rect.height * scale : rect.height
                    )
                    .clipShape(.rect(cornerRadius:  animateView ? 0 : 10))
                    .offset(x: animateView ? 0 : rect.midX, y: animateView ? 0 : rect.minY)
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    GridImageDemoView()
}
