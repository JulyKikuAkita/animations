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

                let startWidth = min(max(firstRect.minX + startOffset, 0), containerSize.width - tabWidth)
                let endWidth = max(min(lastRect.maxX + endOffset, containerSize.width), tabWidth)
                let blockWidth = max(endWidth - startWidth, tabWidth)

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
                    .offset(x: max(min(firstRect.minX + startOffset, lastRect.minX), 0))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .overlay(alignment: .leading) {
                        maskContent()
                            .mask(alignment: .leading) {
                                Rectangle()
                                    .padding(.horizontal, 10)
                                    .frame(width: blockWidth)
                                    .offset(x: clampedDragOffset)
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
                let index = min(max(fallingIndex, 0), lastIndex)

                let newSelection = Array(tabs[index ... lastIndex])
                selection = newSelection
            } else {
                let endResult = lastRect.minX + endOffset
                let fallingIndex = Int((endResult / tabWidth).rounded())
                let index = min(max(fallingIndex, firstIndex), tabs.count - 1)

                let newSelection = Array(tabs[firstIndex ... index])
                selection = newSelection
            }
        }
    }

    private func endResizeDragging(_ firstRect: CGRect) {
        if let lastIndex = selection.indices.last {
            let endResult = firstRect.minX + dragOffset
            let rawFallingIndex = Int((endResult / tabWidth).rounded())

            let maxStartIndex = tabs.count - 1 - lastIndex
            let fallingIndex = min(max(rawFallingIndex, 0), maxStartIndex)

            let newStartIndex = fallingIndex
            let newEndIndex = lastIndex + fallingIndex

            selection = Array(tabs[newStartIndex ... newEndIndex])
        }
    }

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

    private var tabWidth: CGFloat {
        containerSize.width / CGFloat(tabs.count)
    }
}

#Preview {
    SportGroupSliderDemo()
}
