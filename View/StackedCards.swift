//
//  StackedCards.swift
//  animation

import SwiftUI

struct StackedCards<Content: View, Data: RandomAccessCollection>: View where Data.Element: Identifiable{
    var items: Data
    var stackedDisplayCount: Int = 2
    var spacing: CGFloat = 5
    var itemHeight: CGFloat
    @ViewBuilder var content: (Data.Element) -> Content
    
    var body: some View {
        GeometryReader {
            let size = $0.size
            
            ScrollView(.vertical) {
                VStack(spacing: spacing) {
                    ForEach(items) { item in
                        content(item)
                            .frame(height: itemHeight)
                            .visualEffect { content, geometryProxy in
                                content
                            }
                    }
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
        }
    }
    
// TODO: 04:36
    //https://www.youtube.com/watch?v=8ZI2CVHthWU&list=PLimqJDzPI-H97JcePxWNwBXJoGS-Ro3a-&index=106 
    /// Offset & scaling values for each item to make it look like a stack
    func offset(_ proxy: GeometryProxy) -> CGFloat {
        return 0
    }
    
    func scale(_ proxy: GeometryProxy) -> CGFloat {
        return 0
    }
}

#Preview {
    StackedScrollView()
        .preferredColorScheme(.dark)
}
