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
        }
        .opacity(coordinator.hideRootView ? 0 : 1)
        .scrollDisabled(coordinator.hideRootView)
        /// disable user interaction for the source view when in animation, vice versa
        .allowsHitTesting(!coordinator.hideRootView)
        .overlay {
            GridImageDetailView()
                .environment(coordinator)
                .allowsHitTesting(coordinator.hideLayer)
        }
    }

    /// Post card view
    @ViewBuilder
    func PostCardView(_ post: PhotoItem) -> some View {
        GeometryReader {
            let frame = $0.frame(in: .global)

            ImageView(post: post)
                .clipShape(.rect(cornerRadius: 10))
                .contentShape(.rect(cornerRadius: 10))
                .onTapGesture {
                    coordinator.toggleView(show: true, frame: frame, post: post)
                }
        }
        .frame(height: 240) /// update frame height won't impact animation
    }
}

#Preview {
    GridImageDemoView()
}
