//
//  SortableIOS26GridView.swift
//  animation
//
//  Created on 1/28/26.

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
                        CustomLongPressGesture(onChanged: { location, offset in
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

/// Not able to use SwiftUI's LongPressGesture() (break other gesture) thus implement using UIKit
private struct CustomLongPressGesture: UIGestureRecognizerRepresentable {
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
