//
//  TimelineSliderIOS27.swift
//  animation
//
//  Created on 8/4/26.

import SwiftUI

struct SportGroupSliderDemo: View {
    @State private var selection: [Sport] = [.basketball, .skiing]
    var body: some View {
        VStack {
            SportGroupSlider(selection: $selection)
        }
        .padding()
    }
}

struct SportGroupSlider<Item: GroupTabItem>: View {
    @Binding var selection: [Item]
    /// View Properties
    @State private var containerSize: CGSize = .zero
    @State private var itemRects: [Item: CGRect] = [:]
    /// Gesture Properties
    @GestureState private var isActive: Bool = false
    @State private var startOffset: CGFloat = 0
    @State private var endOffset: CGFloat = 0
    @State private var dragOffset: CGFloat = 0

    /// Three ways to change the selected range while dragging, all measured in pixel space and only
    /// converted back into tab indices once the drag ends (see the `endResize...` functions below):
    ///  1. Drag the block's body      -> shifts the whole range by `dragOffset`   (`endResizeDragging`)
    ///  2. Drag the leading handle    -> grows/shrinks from the start by `startOffset` (`endResizeTranslation(isLeading: true)`)
    ///  3. Drag the trailing handle   -> grows/shrinks from the end by `endOffset`     (`endResizeTranslation(isLeading: false)`)
    /// All three offsets reset to 0 once their gesture ends, because by then `selection` (and therefore
    /// `itemRects`) already reflects the new range.
    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.symbolImage) { tab in
                tabItemView(for: tab, tint: .gray)
                    .onGeometryChange(for: CGRect.self) {
                        $0.frame(in: .named("SPORT_CONTAINER"))
                    } action: { newValue in
                        itemRects[tab] = newValue
                    }
            }
        }
        .frame(height: 55)
        .frame(maxWidth: .infinity)
        .contentShape(.rounded())
        .overlay(alignment: .leading) {
            /// setup drag indicator
            if let firstSelected = selection.first, let lastSelected = selection.last {
                let firstRect = itemRects[firstSelected] ?? .zero
                let lastRect = itemRects[lastSelected] ?? .zero

                /// Live pixel bounds of the highlighted block while a resize handle is mid-drag
                /// (`startOffset`/`endOffset` are 0 when nothing is being dragged, so these collapse
                /// to the selection's actual rect in that case).
                /// `startWidth`: left edge of the block, clamped to `[0, containerWidth - tabWidth]` so
                /// dragging the leading handle can't push the block off the left edge of the container,
                /// or so far right that less than one tab's worth of room is left for it.
                let startWidth = min(max(firstRect.minX + startOffset, 0), containerSize.width - tabWidth)
                /// `endWidth`: right edge of the block, clamped to `[tabWidth, containerWidth]` - the
                /// mirror image of `startWidth` for the trailing handle.
                let endWidth = max(min(lastRect.maxX + endOffset, containerSize.width), tabWidth)
                /// One-sided floor (not a full clamp): guarantees the block is always at least one tab
                /// wide, even mid-drag when `startWidth`/`endWidth` briefly cross each other.
                let blockWidth = max(endWidth - startWidth, tabWidth)

                /// Offset for dragging the whole block (not resizing it). The block's absolute left edge
                /// is `startWidth + clampedDragOffset`, so this clamps that sum to stay inside the
                /// container: `>= -startWidth` keeps the left edge `>= 0`, and
                /// `<= containerWidth - blockWidth - startWidth` keeps the right edge `<= containerWidth`.
                let clampedDragOffset = min(max(dragOffset, -startWidth), containerSize.width - blockWidth - startWidth)
                /// Drag area indicator
                RoundedRectangle(cornerRadius: 20)
                    .fill(.primary.opacity(0.12))
                    .strokeBorder(.primary, lineWidth: 1)
                    .frame(width: blockWidth)
                    .offset(x: clampedDragOffset)
                    .overlay {
                        Rectangle()
                            .foregroundStyle(Color.clear)
                            .contentShape(.rect)
                            .gesture(
                                DragGesture(minimumDistance: 0, coordinateSpace: .named("SPORT_CONTAINER")).onChanged { value in
                                    dragOffset = value.translation.width
                                }.onEnded { _ in
                                    withAnimation(.iSpring()) {
                                        endResizeDragging(firstRect)
                                        dragOffset = 0
                                    }
                                }
                            )
                            /// add resizing blocks on both ends
                            .padding(.horizontal, 10)
                    }
                    .overlay(alignment: .leading) {
                        UnevenRoundedRectangle(topLeadingRadius: 20, bottomLeadingRadius: 20)
                            .frame(width: 10)
                            .overlay {
                                Capsule()
                                    .fill(.windowBackground)
                                    .frame(width: 2, height: 30)
                            }
                            .gesture(
                                DragGesture(minimumDistance: 0, coordinateSpace: .named("SPORT_CONTAINER")).onChanged { value in
                                    startOffset = value.translation.width
                                }.onEnded { _ in
                                    withAnimation(.iSpring()) {
                                        endResizeTranslation(isLeading: true)
                                        startOffset = 0
                                    }
                                }
                            )
                            .offset(x: clampedDragOffset)
                    }
                    .overlay(alignment: .trailing) {
                        UnevenRoundedRectangle(bottomTrailingRadius: 20, topTrailingRadius: 20)
                            .frame(width: 10)
                            .overlay {
                                Capsule()
                                    .fill(.windowBackground)
                                    .frame(width: 2, height: 30)
                            }
                            .gesture(
                                DragGesture(minimumDistance: 0, coordinateSpace: .named("SPORT_CONTAINER")).onChanged { value in
                                    endOffset = value.translation.width
                                }.onEnded { _ in
                                    withAnimation(.iSpring()) {
                                        endResizeTranslation(isLeading: false)
                                        endOffset = 0
                                    }
                                }
                            )
                            .offset(x: clampedDragOffset)
                    }
                    /// Resting position of the whole block group (before `clampedDragOffset` is added by
                    /// the overlays above), clamped to `[0, lastRect.minX]`: it can't sit left of the
                    /// container, and can't sit right of where the last selected tab begins - otherwise
                    /// a leading-edge drag could visually push the block past the end of the selection.
                    .offset(x: max(min(firstRect.minX + startOffset, lastRect.minX), 0))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .overlay(alignment: .leading) {
                        maskContent()
                            .mask(alignment: .leading) {
                                Rectangle()
                                    .padding(.horizontal, 10)
                                    .frame(width: blockWidth)
                                    .offset(x: clampedDragOffset)
                                    /// Same clamp as above - the mask window has to track the visible
                                    /// block exactly, or the "selected" (tinted) icons would drift out
                                    /// from under it.
                                    .offset(x: max(min(firstRect.minX + startOffset, lastRect.minX), 0))
                            }
                            .allowsHitTesting(false)
                    }
            }
        }
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(.bar)
                .strokeBorder(Color.gray.tertiary, lineWidth: 1)
        }
        .onGeometryChange(for: CGSize.self) {
            $0.size
        } action: { newValeu in
            containerSize = newValeu
        }
        .coordinateSpace(.named("SPORT_CONTAINER"))
        .onChange(of: selection) { _, newValue in
            verifySelection(newValue)
        }
        .onAppear {
            verifySelection(selection)
        }
    }

    @ContentBuilder
    private func tabItemView(for item: Item, tint _: Color) -> some View {
        Image(systemName: item.symbolImage)
            .font(.body)
            .foregroundStyle(.tint)
            .frame(maxWidth: .infinity)
            .frame(height: 55)
    }

    @ContentBuilder
    private func maskContent() -> some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.symbolImage) { tab in
                tabItemView(for: tab, tint: .primary)
            }
        }
    }

    /// Called when a resize-handle drag ends: converts the handle's final pixel position back into a
    /// tab index and rebuilds `selection` as a contiguous run. Every tab is `tabWidth` wide starting at
    /// x = 0, so `pixelX / tabWidth` gives a (fractional) tab index, and `.rounded()` snaps to the
    /// nearest tab boundary.
    private func endResizeTranslation(isLeading: Bool) {
        if let firstSelection = selection.first,
           let lastSelection = selection.last,
           let firstIndex = tabs.firstIndex(of: firstSelection),
           let lastIndex = tabs.firstIndex(of: lastSelection),
           let firstRect = itemRects[firstSelection],
           let lastRect = itemRects[lastSelection]
        {
            if isLeading {
                let endResult = (firstRect.minX) + startOffset
                let fallingIndex = Int((endResult / tabWidth).rounded())
                /// Clamp to `[0, lastIndex]`: the leading edge can't move before the first tab, and
                /// can't cross past the trailing edge's tab (that would invert the range).
                let index = min(max(fallingIndex, 0), lastIndex)

                let newSelection = Array(tabs[index ... lastIndex])
                selection = newSelection
            } else {
                let endResult = lastRect.minX + endOffset
                let fallingIndex = Int((endResult / tabWidth).rounded())
                /// Clamp to `[firstIndex, tabs.count - 1]`: the trailing edge can't cross before the
                /// leading edge's tab, and can't move past the last tab in the list.
                let index = min(max(fallingIndex, firstIndex), tabs.count - 1)

                let newSelection = Array(tabs[firstIndex ... index])
                selection = newSelection
            }
        }
    }

    /// Called when a whole-block drag ends: shifts the *entire* selected range by however many tabs it
    /// was dragged, keeping the range's length (number of selected tabs) unchanged.
    private func endResizeDragging(_ firstRect: CGRect) {
        if let lastIndex = selection.indices.last {
            let endResult = firstRect.minX + dragOffset
            let rawFallingIndex = Int((endResult / tabWidth).rounded())

            /// `lastIndex` here is `selection.indices.last`, i.e. (selection count - 1) - the range's
            /// span, not a tab index. `maxStartIndex` is the furthest right the range's start can land
            /// while still leaving room for that same span before the end of `tabs`.
            let maxStartIndex = tabs.count - 1 - lastIndex
            /// Clamp to `[0, maxStartIndex]`: the range can't start before tab 0, and can't start so
            /// far right that its end would run past the last tab.
            let fallingIndex = min(max(rawFallingIndex, 0), maxStartIndex)

            let newStartIndex = fallingIndex
            let newEndIndex = lastIndex + fallingIndex

            selection = Array(tabs[newStartIndex ... newEndIndex])
        }
    }

    /// This slider only supports one contiguous run of tabs, but `selection` is an externally-settable
    /// `@Binding`, so a caller could hand it a gap-filled or out-of-order array. Normalize it back to a
    /// contiguous range (or a single tab, if `newValue`'s first/last are out of order) whenever it
    /// changes or the view first appears.
    private func verifySelection(_ newValue: [Item]) {
        if let first = newValue.first, let last = newValue.last,
           let firstIndex = tabs.firstIndex(of: first),
           let lastIndex = tabs.firstIndex(of: last)
        {
            if lastIndex >= firstIndex {
                let newSelection = Array(tabs[firstIndex ... lastIndex])
                if newSelection != selection {
                    selection = newSelection
                }
            } else {
                selection = [tabs[firstIndex]]
            }
        }
    }

    private var tabs: [Item] {
        Array(Item.allCases)
    }

    /// Tabs are laid out in an evenly-spaced `HStack`, so tab `i`'s `minX` is `i * tabWidth` - this is
    /// what lets the `endResize...` functions convert a raw pixel position back into a tab index by
    /// dividing by `tabWidth`.
    private var tabWidth: CGFloat {
        containerSize.width / CGFloat(tabs.count)
    }
}

#Preview {
    SportGroupSliderDemo()
}
