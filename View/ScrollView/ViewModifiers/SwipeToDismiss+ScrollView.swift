//
//  SwipeToDismiss+ScrollView.swift
//  animation
//
//  Created on 3/20/26.

import SwiftUI

private struct DemoSwipeToMissWithScrollView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("Post") {
                    InsideView()
                }
            }
            .navigationTitle("Home")
        }
    }
}

private struct InsideView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 10) {
                DummyMessagesView(count: 13)
            }
            .padding(15)
        }
        .swipeToDismiss(120, onDismiss: {
            dismiss()
        })
    }
}

/// Limited to ScrollView
extension ScrollView {
    @MainActor @ViewBuilder
    func swipeToDismiss(_ threshold: CGFloat, onDismiss: @escaping () -> Void) -> some View {
        modifier(SwipeToDismiss(threshold: threshold, onDismiss: onDismiss))
    }
}

// Swiftlint:disable:next function_body_length
struct SwipeToDismiss: ViewModifier {
    var threshold: CGFloat
    var onDismiss: () -> Void
    /// View Properties
    @State private var scrollOffset: CGFloat = 0
    @GestureState private var isDragging: Bool = false
    @State private var isEligible: Bool = false
    @State private var isDismissTriggered: Bool = false
    @Environment(\.colorScheme) private var scheme
    func body(content: Content) -> some View {
        content
            .contentShape(.rect)
            /// From iOS 18+  Simultaneous Gesture works with scroll view
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .updating($isDragging, body: { _, out, _ in
                        out = true
                    })
            )
            .overlay(alignment: .bottom) {
                /// Bottom drag indicator
                let bottomOffset: CGFloat = scrollOffset < 0 ? -scrollOffset : 0
                /// offset movement
                let movement: CGFloat = 50
                let movementProgress: CGFloat = max(min(bottomOffset / movement, 1), 0)
                let progress: CGFloat = (bottomOffset - movement) / (threshold - movement)
                let cappedProgress: CGFloat = isEligible ? (isDismissTriggered ? 1 : max(min(progress, 1), 0)) : 0
                let isFull: Bool = cappedProgress == 1

                ZStack {
                    Circle()
                        .opacity(isFull ? 1 : 0)
                    ZStack {
                        Circle()
                            .trim(from: 0, to: cappedProgress / 2)
                            .stroke(lineWidth: 3)
                            .rotation(.init(degrees: 90))

                        Circle()
                            .trim(from: 0, to: cappedProgress / 2)
                            .stroke(lineWidth: 3)
                            .rotation(.init(degrees: 90))
                            .scale(x: -1)
                    }
                    .padding(3)

                    /// Arrow with rotation effect
                    let tint: Color = scheme == .dark ? Color.black : Color.white
                    Image(systemName: "chevron.down")
                        .font(.title3)
                        .foregroundStyle(isFull ? tint : .primary)
                        .rotationEffect(.init(degrees: cappedProgress * 90))
                }
                .frame(width: 55, height: 55)
                /// create a bounce animation when reach full
                .keyframeAnimator(initialValue: 1.0, trigger: isFull, content: { content, scale in
                    content
                        .scaleEffect(scale)
                }, keyframes: { _ in
                    CubicKeyframe(1.1, duration: 0.15)
                    CubicKeyframe(1, duration: 0.15)
                })
                .allowsHitTesting(false)
                .offset(y: movement - (movement * movementProgress))
                .opacity(movementProgress)
                /// haptaic feedback when reach full
                .sensoryFeedback(.selection, trigger: isFull) { _, newValue in
                    newValue
                }
            }
            .onScrollGeometryChange(for: CGFloat.self) {
                let offset = $0.contentOffset.y + $0.contentInsets.top
                let contentHeight = $0.contentSize.height
                let containerHeight = $0.containerSize.height
                /// Calculating offset from bottom (bottom => 0)
                return max(contentHeight - containerHeight, 0) - offset
            } action: { _, newValue in
                scrollOffset = newValue
                checkAndDismiss(newValue) // triggers on scroll, but may miss on drag gesture
            }
            .onChange(of: isDragging) { _, newValue in
                if newValue {
                    isEligible = scrollOffset < (threshold * 1.2)
                }
                /// guarantee state offset is triggered even when drag slowly
                checkAndDismiss(scrollOffset)
            }
    }

    func checkAndDismiss(_ offset: CGFloat) {
        if !isDragging, isEligible, -scrollOffset >= threshold, !isDismissTriggered {
            onDismiss()
            isDismissTriggered = true
        }

        /// Reset state after reach bottom, don't use 0, use -10 for safer trigger
        if isDismissTriggered, !(offset.rounded() <= -10), !isDragging {
            isDismissTriggered = false
        }
    }
}

#Preview {
    DemoSwipeToMissWithScrollView()
}
