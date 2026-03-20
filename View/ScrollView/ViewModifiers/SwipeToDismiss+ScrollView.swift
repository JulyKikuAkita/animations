//
//  SwipeToDismiss+ScrollView.swift
//  animation
//
//  Created on 3/20/26.

import SwiftUI

/// Limited to ScrollView
extension ScrollView {
    @MainActor @ViewBuilder
    func swipeToDismiss(_ threshold: CGFloat, onDismiss: @escaping () -> Void) -> some View {
        modifier(SwipeToDismiss(threshold: threshold, onDismiss: onDismiss))
    }
}

struct SwipeToDismiss: ViewModifier {
    var threshold: CGFloat
    var onDismiss: () -> Void
    /// View Properties
    @State private var scrollOffset: CGFloat = 0
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                /// Bottom drag indicator
                ZStack {
                    Circle()
                }
                .frame(width: 55, height: 55)
                .allowsHitTesting(false)
            }
            .onScrollGeometryChange(for: CGFloat.self) {
                let offset = $0.contentOffset.y + $0.contentInsets.top
                let contentHeight = $0.contentSize.height
                let containerHeight = $0.containerSize.height
                /// Calculating offset from bottom (bottom => 0)
                return max(contentHeight - containerHeight, 0) - offset
            } action: { _, newValue in
                scrollOffset = newValue
            }
    }
}
