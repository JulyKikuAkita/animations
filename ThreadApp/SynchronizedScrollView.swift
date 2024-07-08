//
//  SynchronizedScrollView.swift
//  ThreadApp
// tODO: 14:58 https://www.youtube.com/watch?v=M-iWP2l9-Xg&list=PLimqJDzPI-H97JcePxWNwBXJoGS-Ro3a-&index=59

import SwiftUI

struct SynchronizedScrollView: View {
    /// View Properties
    @State private var posts: [Post] = samplePosts
    @State private var showDetailView: Bool = false
    @State private var detailViewAnimation: Bool = false
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
                    detailViewAnimation: $detailViewAnimation,
                    selectedPicID: $selectedPicID
                ) { id in
                    /// Updating scroll position
                    if let index = posts.firstIndex(where: { $0.id == selectedPost.id}) {
                        posts[index].scrollPosition = id
                    }
                }
                .transition(.offset(y: 5)) /// try use identity transition to see the diff
            }
        }
        .overlayPreferenceValue(OffsetKey.self, { value in
             GeometryReader { proxy in
                 if let selectedPicID,
                    let source = value[selectedPicID.uuidString],
                    let destination = value["DESTINATION\(selectedPicID.uuidString)"],
                    let picItem = selectedImage(), showDetailView {
                         let sRect = proxy[source]
                         let dRect = proxy[destination]
                         
                         Image(picItem.image)
                         .resizable()
                         .aspectRatio(contentMode: .fill)
                         .frame(
                            width: detailViewAnimation ? dRect.width: sRect.width,
                            height: detailViewAnimation ? dRect.height : sRect.height
                         )
                         .clipShape(.rect(cornerRadius: detailViewAnimation ? 0 : 10))
                         .offset(x: detailViewAnimation ? dRect.minX : sRect.minX, y: detailViewAnimation ? dRect.minY : sRect.minY)
                         .allowsHitTesting(false)
                     }
                }
        })
    }
    
    func selectedImage() -> PicItem? {
        if let pic = selectedPost?.pics.first(where: { $0.id == selectedPicID }) {
            return pic
        }
        return nil
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
                                .anchorPreference(
                                    key: OffsetKey.self,
                                    value: .bounds,
                                    transform: { anchor in
                                        return [pic.id.uuidString: anchor]
                                })
                                .onTapGesture {
                                    selectedPost = post
                                    selectedPicID = pic.id
                                    showDetailView = true
                                }
                                .contentShape(.rect)
                                .opacity(selectedPicID == pic.id ? 0 : 1)
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
    @Binding var detailViewAnimation: Bool
    @Binding var selectedPicID: UUID?
    var updateScrollPosition: (UUID?) -> ()
    /// View Properties
    @State private var detailScrollPosition: UUID?
    
    /// Dispatch Tasks
    @State private var startTask1: DispatchWorkItem?
    @State private var startTask2: DispatchWorkItem?

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(post.pics) { pic in
                    Image(pic.image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .containerRelativeFrame(.horizontal)
                        .clipped()
                        .anchorPreference(
                            key: OffsetKey.self,
                            value: .bounds,
                            transform: { anchor in
                                return ["DESTINATION\(pic.id.uuidString)": anchor]
                        })
                        .opacity(selectedPicID == pic.id ? 0 : 1)
                }
            }
            .scrollTargetLayout()
        }
        .scrollPosition(id: $detailScrollPosition)
        .background(.gray.opacity(0.2))
        .opacity(detailViewAnimation ? 1 : 0)
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.hidden)
        /// close button
        .overlay(alignment: .topLeading) {
            Button("", systemImage: "xmark.circle.fill") {
                cancellingPreviousTasks()

                updateScrollPosition(detailScrollPosition)
                selectedPicID = detailScrollPosition

                /// Giving some time to set scroll position for hero animation
                initiateTask(ref: &startTask1, task: .init(block: {
                    withAnimation(.snappy(duration: 0.3, extraBounce: 0)) {
                        detailViewAnimation = false
                    }
                    
                    /// Animated and removing detail View
                    initiateTask(ref: &startTask2, task: .init(block: {
                        showDetailView = false
                        selectedPicID = nil
                    }), duration: 0.3)
                }), duration: 0.05)
            }
            .font(.title)
            .foregroundStyle(.white.opacity(0.8), .white.opacity(0.15))
            .padding()
        }
        .onAppear {
            cancellingPreviousTasks()
//            print("\(selectedPicID) \(detailScrollPosition)")

            /// avoid multiple calls
            guard detailScrollPosition == nil else { return }
            detailScrollPosition = selectedPicID /// make sure carousel start from the select image
            
            /// Giving some time to set scroll position for hero animation
            initiateTask(ref: &startTask1, task: .init(block: {
                withAnimation(.snappy(duration: 0.3, extraBounce: 0)) {
                    detailViewAnimation = true
                }
                
                /// Animated and removing Layer View
                initiateTask(ref: &startTask2, task: .init(block: {
                    selectedPicID = nil
                }), duration: 0.3)
            }), duration: 0.05)
        }
    }
    
    func initiateTask(ref: inout DispatchWorkItem?, task: DispatchWorkItem, duration: CGFloat) {
        ref = task
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: task)
    }
    
    func cancellingPreviousTasks() {
//        if let startTask1, let startTask2{
//            startTask1.cancel()
//            startTask2.cancel()
//            self.startTask1 = nil
//            self.startTask2 = nil
//        }
        
        if let startTask1 {
            startTask1.cancel()
            self.startTask1 = nil
        }
        
        if let startTask2 {
            startTask2.cancel()
            self.startTask2 = nil
        }
        
    }
}
