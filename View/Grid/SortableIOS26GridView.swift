//
//  SortableIOS26GridView.swift
//  animation
//
//  Created on 1/28/26.
//  Standalone demo (not wired into the app's demo browser; preview-only).
//
//  TODO: Filename mismatch
//        The `IOS26` suffix is misleading — this file uses NO
//        iOS 26-only APIs (no `@available(iOS 26.0, *)`, no
//        `.glassEffect`, no `ConcentricRectangle`). It compiles on
//        iOS 17.1+ (gating APIs are `onGeometryChange` and
//        `UIGestureRecognizerRepresentable`). Either drop the
//        `IOS26` suffix or add iOS 26 enhancements to justify the
//        name. Compare with `View/CustomMenu/CustomSideMenu+iOS26.swift`,
//        which DOES use `ConcentricRectangle` and earns its suffix.
//
//  Learning point
//  ──────────────
//  Drag-to-reorder grid with LIVE preview that follows the finger:
//  long-press a cell → a floating preview "lifts" out and tracks
//  the drag → cells underneath shuffle aside as the preview passes
//  over them → release drops the cell into the new slot.
//
//  Generic over THREE type parameters
//  ──────────────────────────────────
//  `SortableIOS26GridView<Content, DraggingPreview, Data>`:
//    • `Content` — what each grid cell looks like at rest.
//    • `DraggingPreview` — what the floating "I'm being dragged"
//      view looks like (often a scaled-up version of `Content`).
//    • `Data` — a `RandomAccessCollection` of items conforming to
//      `SortableGridProtocol` (provides `id` + a mutable `position:
//      CGRect` for the helper to write back to).
//  This is the price of reusability — three closures plus a binding
//  to the data — but the call site stays clean.
//
//  Mechanics
//  ─────────
//    1. Each cell records its own `frame(in: .named(coordSpace))`
//       via `onGeometryChange` and writes back to the model's
//       `position`.
//    2. Long-press lifts the dragging preview; subsequent pan
//       updates set its `offset` directly off
//       `gesture.translation`.
//    3. As the preview moves, the gesture coordinator computes the
//       overlap with each cell's recorded `position`. The cell with
//       the largest overlap is the swap target; we swap data items
//       and animate the move.
//    4. Coordinate-space conversion via
//       `context.converter.convert(_:from:to:)` makes the gesture's
//       UIKit coords agree with the SwiftUI named coordinate space.
//
//  Key APIs
//  ────────
//  • `UIGestureRecognizerRepresentable` (iOS 18+) — bridge to
//    `UILongPressGestureRecognizer`.
//  • `coordinateSpace(.named("..."))` — the shared frame-of-
//    reference for cell geometry and gesture location.
//  • `onGeometryChange(for: CGRect.self)` — frame capture per cell.
//  • `SortableGridProtocol` — file-private protocol bundling
//    `id: Hashable` and `position: CGRect` so the helper can write
//    layout state back into the model.
//
//  How to apply
//  ────────────
//  Use when reorder needs a LIVE follow-finger preview (Photos
//  arrange-mode, Home-Screen icon edit). For simpler cases without
//  a preview, [[GridView]] is a one-modifier solution. For
//  multi-select drag-select (lasso), [[Grid+PanGestureView]].
//
//  See also
//  ────────
//  • GridView.swift — simplest reorder, native `.draggable`.
//  • Grid+PanGestureView.swift — drag-select with auto-scroll;
//    same UIKit-bridge philosophy, different interaction.
//
import SwiftUI

protocol SortableGridProtocol: Identifiable {
    var position: CGRect { get set }
}

struct GridICube: Identifiable, SortableGridProtocol {
    var id: String = UUID().uuidString
    var color: Color
    var position: CGRect = .zero
}

let gridItems: [GridICube] = [
    .init(color: .brown),
    .init(color: .pink),
    .init(color: .red),
    .init(color: .green),
    .init(color: .yellow),
    .init(color: .orange),
]

struct SortableGridDemoView: View {
    @State private var items: [GridICube] = gridItems
    @State private var toggle: Bool = false
    var body: some View {
        SortableIOS26GridView(isScrollable: toggle, config: .init(), items: $items) { item in
            itemView(item)
        } draggingPreview: { previewItem in
            itemView(previewItem)
        } onDraggingChange: { location, offset, isDragging in
            /// callback for auto scrolling
            print("location: \(location), offset: \(offset), isDragging: \(isDragging)")
        }
        .onTapGesture {
            toggle.toggle()
        }
        .padding(15)
    }

    func itemView(_ item: GridICube) -> some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(item.color.gradient)
            .frame(height: 80)
    }
}

struct SortableGridConfig {
    var spacing: CGFloat = 10
    var count: Int = 4
    var previewScale: CGFloat = 1.06
}

struct SortableIOS26GridView<Content: View, DraggingPreview: View, Data: RandomAccessCollection>: View where
    Data.Element: SortableGridProtocol,
    Data: MutableCollection, Data: RangeReplaceableCollection
{
    var isScrollable: Bool = false // no dynamic update
    var config: SortableGridConfig
    @Binding var items: Data
    @ViewBuilder var content: (Data.Element) -> Content
    @ViewBuilder var draggingPreview: (Data.Element) -> DraggingPreview
    var onDraggingChange: (_ location: CGPoint, _ offset: CGSize, _ isDragging: Bool) -> Void
    /// View Properties
    @State private var isDragging: Bool = false
    @State private var draggingItem: Data.Element?
    @State private var draggingStartRect: CGRect?
    @State private var draggingOffset: CGSize = .zero
    @State private var newDraggingRect: CGRect = .zero
    @State private var swapLock: Bool = false
    var body: some View {
        Group {
            if isScrollable {
                ScrollView(.vertical) {
                    gridContent()
                }
            } else {
                gridContent()
            }
        }
        .overlay(alignment: .topLeading) {
            if let draggingItem, let draggingStartRect {
                draggingPreview(draggingItem)
                    .disabled(true)
                    .allowsTightening(false)
                    .frame(width: draggingStartRect.width, height: draggingStartRect.height)
                    .animation(.snappy(duration: 0.3, extraBounce: 0)) { content in
                        content
                            .scaleEffect(isDragging ? config.previewScale : 1)
                    }
                    .offset(x: draggingStartRect.minX, y: draggingStartRect.minY)
                    .offset(draggingOffset)
            }
        }
        /// no interaction while dragging items
        .allowsHitTesting(draggingItem == nil)
        .coordinateSpace(name: "SORTABLEGRID")
    }

    private func gridContent() -> some View {
        let columns: [GridItem] = Array(repeating: GridItem(spacing: config.spacing), count: config.count)

        return LazyVGrid(columns: columns, spacing: config.spacing) {
            ForEach($items) { $item in
                content(item)
                    .opacity(draggingItem?.id == item.id ? 0 : 1)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onGeometryChange(for: CGRect.self) {
                        $0.frame(in: .named("SORTABLEGRID"))
                    } action: { newValue in
                        item.position = newValue
                    }
                    .gesture(
                        SortableGridLongPressGesture(onChanged: { location, offset in
                            if draggingItem == nil {
                                draggingItem = item
                                draggingStartRect = item.position
                                DispatchQueue.main.async {
                                    isDragging = true
                                }
                            }
                            draggingOffset = offset
                            reorderData(location: location)
                            onDraggingChange(location, offset, true)
                        }, onEnded: {
                            onDraggingChange(.zero, .zero, false)
                            withAnimation(.snappy(duration: 0.3, extraBounce: 0), completionCriteria: .logicallyComplete) {
                                isDragging = false
                                draggingOffset = .zero
                                if newDraggingRect != .zero {
                                    draggingStartRect = newDraggingRect
                                }
                            } completion: {
                                newDraggingRect = .zero
                                draggingItem = nil
                                draggingStartRect = nil
                            }
                        })
                    )
            }
        }
    }

    private func reorderData(location: CGPoint) {
        if let draggingItem, !swapLock,
           let sourceIndex = items.firstIndex(where: { $0.id == draggingItem.id })
        {
            newDraggingRect = items[sourceIndex].position
            let destinationIndex = items.firstIndex(where: { $0.position.contains(location) })

            guard let destinationIndex, destinationIndex != sourceIndex else { return }

            /// swapping item
            swapLock = true
            withAnimation(.snappy(duration: 0.25, extraBounce: 0)) {
                let item = items.remove(at: sourceIndex)
                items.insert(item, at: destinationIndex)
            }

            DispatchQueue.main.async {
                swapLock = false
            }
        }
    }
}

/// Private: uses UILongPressGestureRecognizer (not UIPanGestureRecognizer) with
/// named coordinate space conversion specific to the sortable grid layout.
/// Cannot be generalized because:
/// - It wraps UILongPressGestureRecognizer, not a pan gesture
/// - It tracks startLocation internally to compute translation from the press origin
/// - It converts global coordinates to a named "SORTABLEGRID" coordinate space via context.converter
/// SwiftUI's built-in LongPressGesture breaks other gestures in this context.
private struct SortableGridLongPressGesture: UIGestureRecognizerRepresentable {
    var duration: CGFloat = 0.16
    var onChanged: (_ location: CGPoint, _ offset: CGSize) -> Void
    var onEnded: () -> Void
    @State private var startLocation: CGPoint?
    func makeUIGestureRecognizer(context _: Context) -> some UILongPressGestureRecognizer {
        let gesture = UILongPressGestureRecognizer()
        gesture.minimumPressDuration = duration
        gesture.numberOfTapsRequired = 0
        gesture.numberOfTouchesRequired = 1
        return gesture
    }

    func updateUIGestureRecognizer(_: UIGestureRecognizerType, context _: Context) {}

    func handleUIGestureRecognizerAction(_ recognizer: UIGestureRecognizerType, context: Context) {
        let state = recognizer.state
        let location = recognizer.location(in: recognizer.view)
        switch state {
        case .began, .changed:
            if startLocation == nil { startLocation = location }
            guard let startLocation else { return }
            let translation: CGSize = .init(
                width: location.x - startLocation.x,
                height: location.y - startLocation.y
            )

            /// convert default global space to local named space
            let localSpaceLocation = context.converter.convert(globalPoint: location, to: .named("SORTABLEGRID"))
            onChanged(localSpaceLocation, translation)
        default:
            startLocation = nil
            onEnded()
        }
    }
}

#Preview {
    SortableGridDemoView()
}
