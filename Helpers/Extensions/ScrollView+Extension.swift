//
//  ScrollView+Extension.swift
//  animation
//
//  Created on 6/5/26.
//
//  Usage:
//      ScrollView { ... }
//          .scrollableHeader(dismissDistance: 60) {
//              MyHeader()
//          }
//
//  The header is pinned to the top safe area and slides off / fades out as the
//  user scrolls down past `dismissDistance`. Releasing the drag snaps the
//  header to fully shown or fully hidden based on progress.
//

import SwiftUI

extension ScrollView {
    func scrollableHeader(
        dismissDistance: CGFloat,
        @ViewBuilder header: @escaping () -> some View
    ) -> some View {
        modifier(
            ScrollableHeaderModifier(
                dismissDistance: dismissDistance,
                header: header
            )
        )
    }
}

private struct ScrollableHeaderModifier<Header: View>: ViewModifier {
    private enum ScrollDirection { case up, down }
    var dismissDistance: CGFloat
    @ViewBuilder var header: Header
    /// View Properties
    @State private var scrollOffset: CGFloat = 0
    @State private var scrollPhase: ScrollPhase = .idle
    @State private var scrollDirection: ScrollDirection? = nil
    @State private var shiftScrollOffset: CGFloat = 0
    @State private var headerProgress: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .top, spacing: 0) {
                header
                    .compositingGroup()
                    .offset(y: headerProgress * -dismissDistance)
                    .opacity(1 - headerProgress)
            }
            .onScrollGeometryChange(for: CGFloat.self) {
                let maxHeight = $0.contentSize.height - $0.containerSize.height
                let offset = $0.contentOffset.y + $0.contentInsets.top
                return min(maxHeight, offset)

            } action: { oldValue, newValue in
                scrollOffset = newValue

                scrollDirection = scrollPhase == .interacting ? (newValue > oldValue ? .up : .down) : nil
                if scrollDirection != nil {
                    let offset = newValue.rounded() - shiftScrollOffset
                    let progress = (offset / dismissDistance).clamped(to: 0 ... 1)
                    headerProgress = progress
                }
            }
            .onScrollPhaseChange { _, newPhase in
                scrollPhase = newPhase
                if newPhase != .interacting {}
                scrollDirection = nil
                withAnimation(.iSpring()) {
                    if headerProgress > 0.5, scrollOffset > dismissDistance {
                        headerProgress = 1
                    } else {
                        headerProgress = 0
                    }
                }
                shiftScrollOffset = max(scrollOffset - (headerProgress * dismissDistance), 0)
            }
            .onChange(of: scrollDirection) { _, newValue in
                guard newValue != nil else { return }
                shiftScrollOffset = max(scrollOffset - (headerProgress * dismissDistance), 0)
            }
    }
}
