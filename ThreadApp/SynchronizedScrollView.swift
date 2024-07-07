//
//  SynchronizedScrollView.swift
//  ThreadApp
// tODO: 3:38 https://www.youtube.com/watch?v=M-iWP2l9-Xg&list=PLimqJDzPI-H97JcePxWNwBXJoGS-Ro3a-&index=59

import SwiftUI

struct SynchronizedScrollView: View {
    @State private var pics: [PicItem] = (1...5).compactMap{ index -> PicItem? in
        return .init(image: "IMG_020\(index + 1)")
    }
    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                VStack(spacing: 15) {
                    CardView(pics)
                }
                .safeAreaPadding(15)
            }
            .navigationTitle("PICS")
        }
    }
    
    @ViewBuilder
    func CardView(_ pics: [PicItem]) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "person.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.teal)
                    .frame(width: 30, height: 30)
                    .background(.background)
                
                VStack(alignment: .leading, spacing: 4, content: {
                    Text("Nanachi")
                        .fontWeight(.semibold)
                        .textScale(.secondary)
                    
                    Text("Nature Pics")
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
                        LazyHStack(spacing: 10) {
                            ForEach(pics) { pic in
                                Image(pic.image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(maxWidth: size.width)
                                    .clipShape(.rect(cornerRadius: 10))
                            }
                        }
                        .scrollTargetLayout()
                    }
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
            .padding(.leading, 45)
            
            
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

struct PicItem: Identifiable, Hashable {
    let id: UUID = .init()
    var image: String
}
