//
//  Grid+PanGestureView.swift
//  animation
//
//  Standalone demo (not wired into the app's demo browser; preview-only).
//  iOS 18+ — `onScrollGeometryChange` is the gating API. Uses
//  `UIPanGestureRecognizer` (via `UIGestureRecognizerRepresentable`)
//  because SwiftUI's `DragGesture` doesn't coordinate well with a
//  parent `ScrollView` for multi-cell drag-select.
//
//  Learning point
//  ──────────────
//  Multi-select color grid with drag-select-and-delete: long-press
//  any cell → enter selection mode → drag finger across cells to
//  add/remove from selection → release to delete the selected
//  cells. Auto-scrolls when the finger nears the top/bottom edge
//  of the grid.
//
//  Two interlocking pieces:
//    1. UIKit pan recognizer for the drag-select. Reads
//       `gesture.location(in:)` against each cell's recorded
//       `frame(in: .global)` (captured via `onGeometryChange`)
//       and toggles the selection set as the finger crosses cells.
//       SwiftUI's `DragGesture` can't do this cleanly inside a
//       `ScrollView` without fighting the scroll's own gesture.
//    2. Edge-zone auto-scroll. Two `ScrollDetectionRegion` views
//       overlaid at the top + bottom 60pt of the grid; when the
//       drag enters one, a `ScrollProperties` state machine ticks
//       the scroll position via `scrollPosition` until the finger
//       leaves the zone. Direction is captured by `ScrollDirection`
//       enum.
//
//  Key APIs
//  ────────
//  • `UIGestureRecognizerRepresentable` (iOS 18+) — modern way to
//    drop a `UIPanGestureRecognizer` into SwiftUI declaratively.
//  • `onGeometryChange(for: CGRect.self)` per cell — records
//    `frame(in: .global)` so the gesture can hit-test by location.
//  • `onScrollGeometryChange(for: ScrollGeometry.self)` — drives
//    the edge-zone auto-scroll.
//  • `LazyVGrid(columns:)` with 4 columns — the grid layout.
//  • Local helper structs `SelectionProperties`, `ScrollProperties`,
//    `ScrollDirection`, `ItemCardView`, `ScrollDetectionRegion` —
//    the demo's state machine, not exported.
//
//  How to apply
//  ────────────
//  Reach for this whenever you need lasso-style multi-select inside
//  a scroll view (Photos, Files, Mail). Watch the magic numbers
//  (4 columns, 60pt edge zone) — they're tuned for phone widths;
//  scale by size class for iPad.
//
//  See also
//  ────────
//  • SortableIOS26GridView.swift — sibling demo using
//    `UILongPressGestureRecognizer` for drag-reorder rather than
//    drag-select. Same UIKit-bridge philosophy, different
//    interaction.
//  • GridView.swift — the simplest grid demo using native
//    `.draggable` + `.dropDestination`. No UIKit reach-through;
//    for cases where you don't need lasso semantics.
//
import SwiftUI

struct GridColorBlockDemoView: View {
    var body: some View {
        GridColorBlockView()
    }
}

struct GridColorBlockView: View {
    /// View properties
    @State private var items: [ColorItem] = []
    @State private var isSelectionEnabled: Bool = false
    @State private var panGesture: UIPanGestureRecognizer?
    @State private var properties: SelectionProperties = .init()
    @State private var scrollProperties: ScrollProperties = .init()

    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 20) {
                Text("Grid View")
                    .font(.title.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .overlay(alignment: .trailing) {
                        Button(isSelectionEnabled ? "Cancel" : "Select") {
                            isSelectionEnabled.toggle()

                            if !isSelectionEnabled {
                                properties = .init()
                            }
                        }
                        .font(.caption)
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                    }

                LazyVGrid(columns: Array(repeating: GridItem(), count: 4)) {
                    ForEach($items) { $item in
                        itemCardView($item)
                    }
                }
            }
            .scrollTargetLayout()
        }
        .safeAreaPadding(15)
        .scrollPosition($scrollProperties.position)
        .overlay(alignment: .top) {
            scrollDetectionRegion()
        }
        .overlay(alignment: .bottom) {
            scrollDetectionRegion(false)
        }
        .onAppear(perform: createRandomColor)
        .onChange(of: isSelectionEnabled) { _, newValue in
            panGesture?.isEnabled = newValue
        }
        .onScrollGeometryChange(
            for: CGFloat.self,
            of: { $0.contentOffset
                .y + $0.contentInsets.top
            },
            action: { _, newValue in
                scrollProperties.currentScrollOffset = newValue
            }
        )
        /// autoScroll when selection hit top or bottom at the specific range in the onScrollGeometryChange
        .onChange(of: scrollProperties.direction) { _, newValue in
            if newValue != .none {
                guard scrollProperties.timer == nil else { return }
                scrollProperties.manualScrollOffset = scrollProperties.currentScrollOffset

                scrollProperties.timer = Timer
                    .scheduledTimer(
                        withTimeInterval: 0.01,
                        repeats: true,
                        block: { _ in
                            if newValue == .up {
                                scrollProperties.manualScrollOffset += 3
                            }

                            if newValue == .down {
                                scrollProperties.manualScrollOffset -= 3
                            }
                            scrollProperties.position.scrollTo(y: scrollProperties.manualScrollOffset)
                        }
                    )

                scrollProperties.timer?.fire()
            } else {
                resetScrollTimer()
            }
        }
        .gesture(
            PanGesture(handle: { gesture in
                if panGesture == nil {
                    panGesture = gesture
                    gesture.isEnabled = isSelectionEnabled
                }
                let state = gesture.state

                if state == .began || state == .changed {
                    onGestureChange(gesture)
                } else {
                    onGestureEnded(gesture)
                }
            })
        )
    }

    @ViewBuilder
    func itemCardView(_ binding: Binding<ColorItem>) -> some View {
        let item = binding.wrappedValue
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            RoundedRectangle(cornerRadius: 10)
                .fill(item.color.gradient)
                .frame(height: 80)
                .onGeometryChange(for: CGRect.self) {
                    $0.frame(in: .global)
                } action: { newValue in
                    binding.wrappedValue.location = newValue
                }
                .overlay(alignment: .topLeading) {
                    if properties.selectedIndices.contains(index),
                       !properties.toBeDeletedIndices.contains(index)
                    {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.black, .white)
                            .padding(5)
                    }
                }
                .overlay { // UIUpdate for tap/unTap selection
                    if isSelectionEnabled {
                        Rectangle()
                            .foregroundStyle(.clear)
                            .contentShape(.rect)
                            .onTapGesture {
                                if properties.selectedIndices.contains(index) {
                                    properties.selectedIndices.removeAll(where: { $0 == index })
                                } else {
                                    properties.selectedIndices.append(index)
                                }

                                properties.previousIndices = properties.selectedIndices
                            }
                            .transition(.identity)
                    }
                }
        }
    }

    @ViewBuilder
    func scrollDetectionRegion(_ isTop: Bool = true) -> some View {
        Rectangle()
            .foregroundStyle(.clear)
            .frame(height: 100)
            .ignoresSafeArea()
            .onGeometryChange(for: CGRect.self) {
                $0.frame(in: .global)
            } action: { newValue in
                if isTop {
                    scrollProperties.topRegion = newValue
                } else {
                    scrollProperties.bottomRegion = newValue
                }
            }
    }

    private func onGestureChange(_ gesture: UIPanGestureRecognizer) {
        let position = gesture.location(in: gesture.view)
        if let fallingIndex = items.firstIndex(where: { $0.location.contains(position) }) {
            if properties.start == nil {
                properties.start = fallingIndex
                properties.isDeleteDrag = properties.previousIndices
                    .contains(fallingIndex)
            }

            properties.end = fallingIndex

            if let start = properties.start, let end = properties.end {
                let indices = (start > end ? end ... start : start ... end).compactMap(\.self)
                if properties.isDeleteDrag {
                    properties.toBeDeletedIndices = Set(
                        properties.previousIndices
                    )
                    .intersection(indices).compactMap(\.self)
                } else {
                    properties.selectedIndices = Set(properties.previousIndices)
                        .union(indices).compactMap(\.self)
                }
            }

            scrollProperties.direction = scrollProperties.topRegion
                .contains(position) ? .down : scrollProperties.bottomRegion
                .contains(position) ? .up : .none
        }
    }

    private func onGestureEnded(_: UIPanGestureRecognizer) {
        for index in properties.toBeDeletedIndices {
            properties.selectedIndices.removeAll(where: { $0 == index })
        }
        properties.toBeDeletedIndices = []

        properties.previousIndices = properties.selectedIndices
        properties.start = nil
        properties.end = nil
        properties.isDeleteDrag = false

        resetScrollTimer()
    }

    private func createRandomColor() {
        guard items.isEmpty else { return }
        let colors: [Color] = [.red, .blue, .purple, .yellow, .black, .indigo, .cyan, .brown, .mint, .orange]

        for _ in 0 ... 4 {
            let sampleItems = colors.shuffled().compactMap { ColorItem(color: $0) }
            items.append(contentsOf: sampleItems)
        }
    }

    private func resetScrollTimer() {
        scrollProperties.manualScrollOffset = 0
        scrollProperties.timer?.invalidate()
        scrollProperties.timer = nil
        scrollProperties.direction = .none
    }

    struct SelectionProperties {
        var start: Int?
        var end: Int?
        var selectedIndices: [Int] = []
        var previousIndices: [Int] = []
        var toBeDeletedIndices: [Int] = []
        var isDeleteDrag: Bool = false
    }

    struct ScrollProperties {
        var position: ScrollPosition = .init()
        var currentScrollOffset: CGFloat = 0
        var manualScrollOffset: CGFloat = 0
        var timer: Timer?
        var direction: ScrollDirection = .none
        /// Regions
        var topRegion: CGRect = .zero
        var bottomRegion: CGRect = .zero
    }

    enum ScrollDirection {
        case up, down, none
    }
}

#Preview {
    GridColorBlockDemoView()
}
