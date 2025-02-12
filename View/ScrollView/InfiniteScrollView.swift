//
//  InfiniteScrollView.swift
//  animation
//

import SwiftUI

struct InfiniteScrollView<Content: View>: View {
    var spacing: CGFloat = 10
    @ViewBuilder var content: Content
    /// View Properties
    @State private var contentSize: CGSize = .zero
    var body: some View {
        GeometryReader {
            let size = $0.size
            
            ScrollView(.horizontal) {
                HStack(spacing: spacing) {
                    Group(subviews: content) { collection in
                        /// Original content
                        HStack(spacing: spacing) {
                            ForEach(collection) { view in
                                    view
                            }
                        }
                        .onGeometryChange(for: CGSize.self) {
                            $0.size
                        } action: { newValue in
                            contentSize = .init(width: newValue.width + spacing, height: newValue.height)
                        }
                        
                        /// Repeating content to create infinite lopping effect
                    }
                }
            }
        }
       
    }
}
