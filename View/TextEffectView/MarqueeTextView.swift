//
//  MarqueeTextView.swift
//  animation
//
// Implement MarqueeText effect using the KeyFrame API
// Appending the original text with gap at the end of the current animation to achieve marquee effect
// Marquee texts: scroll a long text with animation
// use a horizontal scrollView, disabled scroll interactions,
// implement a condition modifier to show repeating text by comparing the text width exceed view size  and parent view width
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
