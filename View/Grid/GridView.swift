//
//  GridView.swift
//  animation
//
//  Created on iOS 17.
//  Standalone demo (not wired into the app's demo browser; preview-only).
//
//  Learning point
//  ──────────────
//  The simplest possible drag-to-reorder grid: `LazyVGrid` of color
//  swatches that the user can long-press and drop into a new
//  position. Uses ONLY native SwiftUI APIs — no UIKit gesture
//  bridge, no manual frame tracking. Read this file as the
//  baseline; the other `View/Grid/` demos add complexity on top.
//
//  Two-modifier pattern:
//    • `.draggable(color)` on each cell — declares the cell as a
//      drag source. The payload (a `Color`) is what the destination
//      receives. SwiftUI handles the lift animation, drag preview,
//      and haptic itself.
//    • `.dropDestination(for: Color.self) { items, location in ... }`
//      on each cell — declares the cell as a drop target. We use
//      the index of the drop target to insert the dragged color in
//      the correct slot.
//  Together those two modifiers replace what was previously a 200-
//  line dance of `onDrag` / `onDrop` / `NSItemProvider` plumbing.
//
//  Key APIs
//  ────────
//  • `.draggable(_:)` — iOS 16+, generic over `Transferable`.
//  • `.dropDestination(for:action:)` — iOS 16+; the `action`
//    closure returns `Bool` for accept/reject.
//  • `LazyVGrid(columns:)` with three flexible columns — standard
//    grid layout.
//  • `.bouncy` animation — the unifying curve for the reorder.
//
//  How to apply
//  ────────────
//  Use whenever your reorder needs are simple (single-item drag,
//  no auto-scroll, no multi-select). For lasso-select see
//  [[Grid+PanGestureView]]; for "press-and-drag-with-live-preview"
//  see [[SortableIOS26GridView]].
//
//  See also
//  ────────
//  • Grid+PanGestureView.swift — UIKit pan gesture for multi-select.
//  • SortableIOS26GridView.swift — UILongPress + custom preview
//    follow-finger.
//  • GridCompositionalLayoutView.swift — dynamic column-count grid.
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
                        GeometryReader { _ in
                            RoundedRectangle(cornerRadius: 10)
                                .fill(color.gradient)
                                /// any object conforms to Transferable protocol
                                /// (DATA, string, image)
                                .draggable(color) {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(.ultraThinMaterial)
                                        .frame(width: 1, height: 1)
                                        .onAppear {
                                            /// set source view item
                                            draggingItem = color
                                        }
                                }
                                .dropDestination(for: Color.self) { _, _ in
                                    draggingItem = nil
                                    return false
                                } isTargeted: { status in
                                    if let draggingItem, status, draggingItem != color {
                                        if let sourceIndex = colors.firstIndex(of: draggingItem),
                                           let destinationIndex = colors.firstIndex(of: color)
                                        {
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
    GridView()
}
