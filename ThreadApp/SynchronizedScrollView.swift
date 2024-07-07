//
//  SynchronizedScrollView.swift
//  ThreadApp


import SwiftUI

struct SynchronizedScrollView: View {
    @State private var pics: [PicItem] = (1...5).compactMap{ index -> PicItem? in
        return .init(image: "IMG_020\(index)")
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
            }
            .frame(height: 200)
        }
    }
}

#Preview {
    SynchronizedScrollView()
}

struct PicItem: Identifiable, Hashable {
    let id: UUID = .init()
    var image: String
}
