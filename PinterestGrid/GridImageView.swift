//
//  GridImageView.swift
//  demoApp

import SwiftUI

struct GridImageDemoView: View {
    var body: some View {
        NavigationStack {
            GridImageView()
                .toolbar(.hidden, for: .navigationBar)
        }
    }
}
struct GridImageView: View {
    /// UI Properties
    var coordinator: UICoordinatorPinterestGrid = .init()
    @State private var posts: [PhotoItem] = sampleItems
    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(alignment: .leading, spacing: 15) {
                Text("Welcome Back!")
                    .font(.largeTitle.bold())
                    .padding(.vertical, 10)
                
                /// Grid image view
                LazyVGrid(columns: Array(repeating: GridItem(spacing: 10), count: 2), spacing: 10) {
                    ForEach(posts) { post in
                        PostCardView(post)
                    }
                }
            }
            .padding(15)
            .background(ScrollViewExtractor {
                coordinator.scrollView = $0
            })
            .overlay {
                
            }
        }
    }
    
    /// Post card view
    @ViewBuilder
    func PostCardView(_ post: PhotoItem) -> some View {
        GeometryReader {
            let frame = $0.frame(in: .global)
            
            if let image = post.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: frame.width, height: frame.height)
                    .clipShape(.rect(cornerRadius: 10))
                    .contentShape(.rect(cornerRadius: 10))
                    .onTapGesture {
                        /// Storing View's Rect
                        coordinator.rect = frame
                        /// Generating scrollView's visible area snapshot
                        coordinator.createVisibleAreaSnapshot()
                    }
            }
        }
        .frame(height: 180)
    }
}

#Preview {
    GridImageDemoView()
}
