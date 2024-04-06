//
//  GridView.swift
//  animation
//
//  Created by IFang Lee on 3/1/24.
//

import SwiftUI

struct GridView: View {
    /// View properties
    @State var colors: [Color] = [.red, .blue, .purple, .yellow, .black, .indigo, .cyan, .brown, .mint, .orange]
    @State private var draggingItem: Color?
    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                let columns = Array(repeating: GridItem(spacing: 10), count: 3)
                LazyVGrid(columns: columns, spacing: 10, content: {
                    ForEach(colors, id: \.self) { color in
                        GeometryReader {
                            let _ = $0.size
                            
                            RoundedRectangle(cornerRadius: 10)
                            .fill(color.gradient)
            
                            /// Drag
                            .draggable(color) { // any object conforms to Transferable protocol (DATA, string, image)
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 1, height: 1)
                                    .onAppear {
                                        /// set source view item
                                        draggingItem = color
                                    }
                            }
                            /// Drop
                            .dropDestination(for: Color.self) { items, location in
                                draggingItem = nil
                                return false
                            } isTargeted: { status in
                                if let draggingItem, status, draggingItem != color {
                                    if let sourceIndex = colors.firstIndex(of: draggingItem),
                                    let destinationIndex = colors.firstIndex(of: color) {
                                        withAnimation(.bouncy) {
                                            let sourceItem = colors.remove(at: sourceIndex)
                                            colors.insert(sourceItem, at: destinationIndex)
                                        }
                                    }
                                }
                            }
                            
                        }
                        .frame(height: 100)

                    }
                })
                .padding(15)
            }
            .navigationTitle("Moving Grid")
        }
    }
}

#Preview {
    ContentView()
}
