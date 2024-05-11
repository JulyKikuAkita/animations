//
//  DetailView.swift
//  demoApp

import SwiftUI

struct DetailView: View {
    @Environment(UICoordinator.self) private var coordinator

    var body: some View {
        GeometryReader {
            let size = $0.size
            
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(coordinator.items) { item in
                        /// Image view
                        ImageView(item, size: size)
                    }
                }
                .scrollTargetLayout()
            }
            /// Making it as a paging view
            .scrollTargetBehavior(.paging)
        }
//        .opacity(coordinator.showDetailView ? 1 : 0)
    }
    
    @ViewBuilder
    func ImageView(_ item: PhotoItem, size: CGSize) -> some View {
        if let image = item.image {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size.width, height: size.height)
                .clipped()
                .contentShape(.rect)
        }
    }
}

#Preview {
    ApplePhotoHomeView()
}
