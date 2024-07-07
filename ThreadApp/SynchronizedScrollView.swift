//
//  SynchronizedScrollView.swift
//  ThreadApp
// tODO: 3:38 https://www.youtube.com/watch?v=M-iWP2l9-Xg&list=PLimqJDzPI-H97JcePxWNwBXJoGS-Ro3a-&index=59

import SwiftUI

struct SynchronizedScrollView: View {
    /// View Properties
    @State private var posts: [Post] = samplePosts
    @State private var showDetailView: Bool = false
    @State private var selectedPicID: UUID?
    @State private var selectedPost: Post?
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                VStack(spacing: 15) {
                    ForEach(posts) { post in
                        CardView(post)

                    }
                }
                .safeAreaPadding(15)
            }
            .navigationTitle("PICS")
        }
        .overlay {
            if let selectedPost, showDetailView {
                DetailView(
                    post: selectedPost,
                    showDetailView: $showDetailView,
                    selectedPicID: $selectedPicID
                ) { id in
                    /// Updating scroll position
                    if let index = posts.firstIndex(
                        where: { $0.id == selectedPost
                            .id}) {
                        posts[index].scrollPosition = id
                    }
                }
                .transition(.offset(y: 5)) /// try use identity transition to see the diff
            }
        }
    }
    
    @ViewBuilder
    func CardView(_ post: Post) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "person.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.teal)
                    .frame(width: 30, height: 30)
                    .background(.background)
                
                VStack(alignment: .leading, spacing: 4, content: {
                    Text(post.username)
                        .fontWeight(.semibold)
                        .textScale(.secondary)
                    
                    Text(post.content)
                })
                
                Spacer(minLength: 0)
                
                Button("", systemImage: "ellipsis") {
                    
                }
                .foregroundStyle(.primary)
                .offset(y: -10)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                GeometryReader {
                    let size = $0.size
                    
                    ScrollView(.horizontal) {
                        HStack(spacing: 10) {
                            ForEach(post.pics) { pic in
                                LazyHStack {
                                    Image(pic.image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(maxWidth: size.width)
                                        .clipShape(.rect(cornerRadius: 10))
                                }
                                .frame(maxWidth: size.width)
                                .frame(height: size.height)
                                .onTapGesture {
                                    selectedPost = post
                                    selectedPicID = pic.id
                                    showDetailView = true
                                }
                                .contentShape(.rect)
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollPosition(id: .init(get: {
                        return post.scrollPosition
                    }, set: { _ in }))
                    .scrollIndicators(.hidden)
                    .scrollTargetBehavior(.viewAligned)
                    .scrollClipDisabled()
                }
                .frame(height: 200)
                
                /// Image buttons
                HStack(spacing: 20) {
                    ImageButton("suit.heart") {
                        
                    }
                    
                    ImageButton("message") {
                        
                    }
                    
                    ImageButton("arrow.2.squarepath") {
                        
                    }
                    ImageButton("paperplane") {
                        
                    }
                }
            }
            .safeAreaPadding(.leading, 45)
            
            
            /// Likes and replies
            HStack(spacing: 10) {
                Image(systemName: "person.circle.fill")
                    .frame(width: 30, height: 30)
                    .background(.background)
                
                Button("10 replies") {
                    
                }
                
                Button("810 likes") {
                    
                }
                .padding(.leading, -5)
                
                Spacer()
            }
            .textScale(.secondary)
            .foregroundStyle(.secondary)
        }
        /// adding vertical line
        .background(alignment: .leading) {
            Rectangle()
                .fill(.secondary)
                .frame(width: 1)
                .padding(.bottom, 30)
                .offset(x: 15, y: 10)
        }
        
        
    }
    
    @ViewBuilder
    func ImageButton(_ icon: String, onTap: @escaping () -> ()) -> some View {
        Button("", systemImage: icon, action: onTap)
            .font(.title3)
            .foregroundStyle(.primary)
    }
}

#Preview {
    SynchronizedScrollView()
}

private struct DetailView: View {
    var post: Post
    @Binding var showDetailView: Bool
    @Binding var selectedPicID: UUID?
    var updateScrollPosition: (UUID?) -> ()
    /// View Properties
    @State private var detailScrollPosition: UUID?
    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(post.pics) { pic in
                    Image(pic.image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .containerRelativeFrame(.horizontal)
                        .clipped()
                }
            }
            .scrollTargetLayout()
        }
        .scrollPosition(id: $detailScrollPosition)
        .background(.black)
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.hidden)
        /// close button
        .overlay(alignment: .topLeading) {
            Button("", systemImage: "xmark.circle.fill") {
                updateScrollPosition(detailScrollPosition)
                showDetailView = false
                selectedPicID = nil
            }
            .font(.title)
            .foregroundStyle(.white.opacity(0.8), .white.opacity(0.15))
            .padding()
        }
        .onAppear {
            /// avoid multiple calls
            guard detailScrollPosition == nil else { return }
            detailScrollPosition = selectedPicID /// make sure carousel start from the select image
        }
        
    }
}
