//
//  MicroInteractionSlider.swift
//  animation

import SwiftUI

struct MicroInteractionSliderView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()

                let config = MicroInteractionSlider.Config(
                    idleText: "Swipe to confirm",
                    onSwipeText: "Confirms Payment",
                    confirmationText: "Success!",
                    tint: .green,
                    foregroundColor: .white
                )

                MicroInteractionSlider(config: config) {}
            }
            .padding(15)
            .navigationTitle(Text("Slide to Confirm"))
        }
    }
}

struct MicroInteractionSlider: View {
    var config: Config
    var onSwiped: () -> Void
    /// View Properties
    @State private var animateText: Bool = false
    @State private var offsetX: CGFloat = 0
    @State private var isCompleted: Bool = false
    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let knobSize = size.height
            let maxLimit = size.width - knobSize
            let progress: CGFloat = isCompleted ? 1 : (offsetX / maxLimit)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(
                        .gray.opacity(0.25)
                            .shadow(.inner(color: .black.opacity(0.2), radius: 10))
                    )

                /// Tint Capsule
                let extraCapsuleWidth = (size.width - knobSize) * progress
                Capsule()
                    .fill(config.tint.gradient)
                    .frame(width: knobSize + extraCapsuleWidth, height: knobSize)
                leadingTextView(size, progress: progress)

                HStack(spacing: 0) {
                    knobView(size, progress: progress, maxLimit: maxLimit)
                        .zIndex(1)
                        .scaleEffect(isCompleted ? 0.6 : 1, anchor: .center)

                    shimmerTextView(size, progress: progress)
                }
            }
        }
        .frame(height: isCompleted ? 50 : config.height)
        .containerRelativeFrame(.horizontal) { value, _ in
            let ratio: CGFloat = isCompleted ? 0.5 : 0.8
            return value * ratio
        }
        .frame(maxWidth: 300)
        .allowsHitTesting(!isCompleted)
    }

    func knobView(_ size: CGSize, progress: CGFloat, maxLimit: CGFloat) -> some View {
        Circle()
            .fill(.background)
            .padding(6)
            .frame(width: size.height, height: size.height)
            .overlay {
                ZStack {
                    Image(systemName: "chevron.right")
                        .opacity(1 - progress)
                        .blur(radius: progress * 10)

                    Image(systemName: "checkmark")
                        .opacity(progress)
                        .blur(radius: (1 - progress) * 10)
                }
                .font(.title3.bold())
            }
            .contentShape(.circle)
            .scaleEffect(isCompleted ? 0.6 : 1, anchor: .center)
            .offset(x: isCompleted ? maxLimit : offsetX)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        /// Limiting to end of the capsule
                        let knobSize = size.height
                        let maxLimit = size.width - knobSize
                        offsetX = min(max(value.translation.width, 0), maxLimit)
                    }.onEnded { _ in
                        if offsetX == maxLimit {
                            onSwiped()
                            /// Stopping shimmer effect
                            animateText = false

                            withAnimation(.smooth) {
                                isCompleted = true
                            }
                        } else {
                            withAnimation(.smooth) {
                                offsetX = 0
                            }
                        }
                    }
            )
    }

    func shimmerTextView(_ size: CGSize, progress: CGFloat) -> some View {
        Text(isCompleted ? config.confirmationText : config.idleText)
            .foregroundStyle(.gray.opacity(0.6))
            .overlay {
                /// Shimmer Effect
                Rectangle()
                    .frame(height: 15)
                    .rotationEffect(.init(degrees: 90))
                    .visualEffect { [animateText] content, proxy in
                        content
                            .offset(x: -proxy.size.width * 1.8)
                            .offset(x: animateText ? proxy.size.width * 1.2 : 0)
                    }
                    .mask(alignment: .leading) {
                        Text(config.idleText)
                    }
                    .blendMode(.softLight)
            }
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            /// make it center
            /// Eliminating knob's radius
            .padding(.trailing, size.height / 2)
            .mask {
                Rectangle()
                    .scale(x: 1 - progress, anchor: .trailing)
            }
            .frame(height: size.height)
            .task {
                withAnimation(Animation.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                    animateText = true
                }
            }
    }

    /// OnSwipe/Confirmation Text View
    func leadingTextView(_ size: CGSize, progress: CGFloat) -> some View {
        ZStack {
            Text(config.onSwipeText)
                .opacity(isCompleted ? 0 : 1)
                .blur(radius: isCompleted ? 10 : 0)

            Text(config.confirmationText)
                .opacity(!isCompleted ? 0 : 1)
                .blur(radius: !isCompleted ? 10 : 0)
        }
        .fontWeight(.semibold)
        .foregroundStyle(config.foregroundColor)
        .frame(maxWidth: .infinity)
        /// to make the view center
        .padding(.trailing, (size.height * (isCompleted ? 0.6 : 1)) / 2)
        .mask {
            Rectangle()
                .scale(x: progress, anchor: .leading)
        }
    }

    struct Config {
        let idleText: String
        let onSwipeText: String
        let confirmationText: String
        let tint: Color
        let foregroundColor: Color
        var height: CGFloat = 70
    }
}

#Preview {
    MicroInteractionSliderView()
}
