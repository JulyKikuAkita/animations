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
    var body: some View {
        SortableIOS26GridView(config: .init(), items: $items) { item in
            itemView(item)
        } draggingPreview: { _ in
            Rectangle()
        } onDraggingChange: { _, _, _ in
        }
        .padding(15)
    }

    func itemView(_ item: GridICube) -> some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(item.color.gradient)
            .frame(height: 150)
    }
}

struct SortableGridConfig {
    var spacing: CGFloat = 10
    var count: Int = 2
}

struct SortableIOS26GridView<Content: View, DraggingPreview: View, Data: RandomAccessCollection>: View where
    Data.Element: SortableGridProtocol,
    Data: MutableCollection
{
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
    var body: some View {
        let columns: [GridItem] = Array(repeating: GridItem(spacing: config.spacing), count: config.count)
        ScrollView(.vertical, showsIndicators: false) {
            LazyVGrid(columns: columns, spacing: config.spacing) {
                ForEach($items) { $item in
                    content(item)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onGeometryChange(for: CGRect.self) {
                            $0.frame(in: .named("SORTABLEGRID"))
                        } action: { newValue in
                            item.position = newValue
                        }
                        .gesture(
                            CustomLongPressGesture(onChanged: { _, _ in
                                if draggingItem == nil {
                                    draggingItem = item
                                    draggingStartRect = item.position
                                    isDragging = true
                                }
                            }, onEnded: {
                                isDragging = false
                                draggingItem = nil
                                draggingStartRect = nil
                            })
                        )
                }
            }
        }
        .overlay(alignment: .topLeading) {
            if let draggingItem, let draggingStartRect {
                draggingPreview(draggingItem)
                    .disabled(true)
                    .allowsTightening(false)
                    .frame(width: draggingStartRect.width, height: draggingStartRect.height)
                    .offset(x: draggingStartRect.minX, y: draggingStartRect.minY)
            }
        }
        .coordinateSpace(name: "SORTABLEGRID")
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

    func handleUIGestureRecognizerAction(_ recognizer: UIGestureRecognizerType, context _: Context) {
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
            onChanged(location, translation)
        default:
            startLocation = nil
            onEnded()
        }
    }
}

#Preview {
    SortableGridDemoView()
}
