//
//  BlurEffectSearchBarView.swift
//  animation
//
//  1. make header sticky
//

import SwiftUI

struct BlurEffectSearchBarDemoView: View {
    var body: some View {
        BlurEffectSearchBarView()
    }
}
struct BlurEffectSearchBarView: View {
    /// View Properties
    @State private var searchText: String = ""
    
    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 15) {
                ForEach(firstSetCards) { item in
                    CardView(item)
                }
            }
            .padding(15)
            .safeAreaInset(edge: .top, spacing: 0) {
                ResizableHeader()
            }
        }
    }
    
    @ViewBuilder
    func ResizableHeader() -> some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Welcome Back")
                        .font(.callout)
                        .foregroundStyle(.gray)
                    
                    Text("Nanachi")
                        .font(.title.bold())
                }
                
                Spacer(minLength: 0)
                
                /// Profile Button
                Button {
                    
                } label: {
                    Image("fox")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(.circle)
                }
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 15)
            
            /// Floating Search Bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                
                TextField("Search Photo", text: $searchText)
                
                /// Microphone Button
                Button {
                    
                } label: {
                    Image(systemName: "microphone.fill")
                        .foregroundStyle(Color.primary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 15)
            .background {
                RoundedRectangle(cornerRadius: 30)
                    .fill(.background
                        .shadow(.drop(color: .black.opacity(0.08), radius: 5, x: 5, y:5))
                        .shadow(.drop(color: .black.opacity(0.05), radius: 5, x: -5, y:-5))
                    )
            }
            .padding(.horizontal, 15)
            .padding(.bottom, 10)
        }
        .visualEffect { content, proxy in
            content
                .offset(y: offsetY(proxy))
        }
    }
    
    nonisolated private func offsetY(_ proxy: GeometryProxy) -> CGFloat {
        let minY = proxy.frame(in: .scrollView(axis: .vertical)).minY
        return minY > 0 ? 0 : -minY
    }
    
    @ViewBuilder
    func CardView(_ item: Card) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            GeometryReader {
                let size = $0.size
                
                Image(item.image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size.width, height: size.height)
                    .clipShape(.rect(cornerRadius: 20))
            }
            .frame(height: 220)
            
            Text("By: \(item.title)")
                .font(.callout)
                .foregroundStyle(.primary.secondary)
        }
    }
}

#Preview {
    BlurEffectSearchBarDemoView()
}
