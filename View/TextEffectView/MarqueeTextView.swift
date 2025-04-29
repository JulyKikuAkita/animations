//
//  MarqueeTextView.swift
//  animation
//
// Implements a MarqueeText effect using the Keyframe API.
// The marquee scrolls long text horizontally by animating a repeating offset.
// To achieve the looping (marquee) effect, the original text is duplicated with a gap and appended,
// creating a seamless scroll as the animation loops.

// Key implementation details:
// - Uses a horizontal ScrollView with scrolling interactions disabled.
// - Measures the text width and compares it to the container width.
//   If the text exceeds the view width, the marquee animation is triggered.
// - Uses Keyframe-based animation to define specific value changes over time (e.g., offset or opacity).
// - Keyframes allow chaining value transitions, such as holding a value, then animating it smoothly.

// Keyframe example:
// A Keyframe defines a specific moment during an animation where a value is set or transitions.
//
// In animations, keyframes control how a property (like position, opacity, or scale) changes over time.
//    •    A keyframe specifies:
//    •    Value: the target value at that point (e.g., opacity = 1.0)
//    •    Duration: how long to hold or transition to the next value
//    •    By chaining multiple keyframes together, you can create complex animations, such as pauses, smooth transitions, or looping behaviors
// LinearKeyframe(0, duration: holdTime)
// LinearKeyframe(1, duration: scrollTime)
// This sequence holds the value at 0, then animates to 1 over time.

import SwiftUI

struct MarqueeTextViewDemo: View {
    var body: some View {
        VStack {
            HStack(spacing: 12) {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 45, height: 45)
                VStack(alignment: .leading, spacing: 6) {
                    MarqueeText(text: "Hello, World! this is Marquee effect using KeyFrame API.")

                    Text("Hi there")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
            }
            .padding(15)
            .background(.background, in: .rect(cornerRadius: 12))
        }
        .padding(15)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.gray.opacity(0.15))
    }
}

struct MarqueeText: View {
    var text: String
    /// View Properties
    @State private var textSize: CGSize = .zero
    @State private var viewSize: CGSize = .zero
    @State private var isMarqueeEnabled: Bool = false
    var body: some View {
        ScrollView(.horizontal) {
            Text(text)
                .onGeometryChange(for: CGSize.self) {
                    $0.size
                } action: { newValue in
                    textSize = newValue
                    isMarqueeEnabled = textSize.width > viewSize.width
                }
                .modifiers { content in
                    if isMarqueeEnabled {
                        content
                            .keyframeAnimator(initialValue: 0.0, repeating: true) { [textSize, gap] content, progress in
                                let offset = textSize.width + gap

                                content
                                    .overlay(alignment: .trailing) {
                                        content.offset(x: offset)
                                    }
                                    .offset(x: -offset * progress)
                            } keyframes: { _ in
                                LinearKeyframe(0, duration: holdTime)
                                LinearKeyframe(1, duration: speed)
                            }
                    } else {
                        content
                    }
                }
        }
        .scrollDisabled(true)
        .scrollIndicators(.hidden)
        .onGeometryChange(for: CGSize.self) {
            $0.size
        } action: { newValue in
            viewSize = newValue
        }
    }

    /// pause time for the next iteration to kick off
    var holdTime: CGFloat {
        2
    }

    var speed: CGFloat {
        6
    }

    /// gap between repeating text
    var gap: CGFloat {
        25
    }
}

private extension View {
    func modifiers(@ViewBuilder content: @escaping (Self) -> some View) -> some View {
        content(self)
    }
}

#Preview {
    NavigationStack {
        MarqueeTextViewDemo()
            .navigationTitle("KeyFrame API")
            .navigationBarTitleDisplayMode(.inline)
    }
}
