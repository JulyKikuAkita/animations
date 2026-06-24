//
//  GlassStyleSlider.swift
//  animation
//
//  Created on 6/23/26.
//
//  Learning point
//  ──────────────
//  Liquid-glass "slide to confirm" slider. Two effects worth dissecting:
//
//  1. **Shimmer text** — a thin, blurred, tilted bar of color slides
//     across the label on a loop. It's done with a MASK, not by drawing
//     a highlight on top. The label is rendered twice: a static dim copy,
//     and a second copy whose visible region is restricted to a moving
//     vertical bar. So the shimmer isn't a new color added — it's the
//     label peeking through a sweeping window. See `shimmer text effect`.
//
//  2. **`.visualEffect` + `.layerEffect` (Metal shader)** — `.visualEffect`
//     lets a view read its own geometry (size/position) at render time and
//     return a modified view, WITHOUT triggering a layout pass. Here it
//     feeds the knob's live x-offset into a `liquidLens` Metal shader that
//     refracts the text underneath the knob — a glass-magnifier look that
//     tracks the drag. See `.visualEffect` below.
//
import SwiftUI

@available(iOS 26.0, *)
struct LiquidGlassCustomSliderDemoView: View {
    var body: some View {
        VStack {
            LiquidGlassCustomSlider(
                text: "emergency call",
                symbol: "sos",
                config: .init(tint: .orange, height: 90)
            ) { _ in

            } onFinished: { _ in
            }
            .frame(maxWidth: 350)
        }
        .preferredColorScheme(.dark)
    }
}

@available(iOS 26.0, *)
struct LiquidGlassCustomSlider: View {
    var text: String
    var symbol: String
    var config: Config
    var onProgressChanged: (CGFloat) -> Void
    var onFinished: (Bool) -> Void
    /// View Properties
    @GestureState private var isActive: Bool = false
    @State private var offsetX: CGFloat = 0
    var body: some View {
        GeometryReader {
            let rect = $0.frame(in: .global)
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(config.tint.opacity(0.08))
                    .stroke(Color.primary.tertiary, lineWidth: 0.3)

                ZStack(alignment: .leading) {
                    Text(text)
                        .font(config.textFont)
                        .foregroundStyle(config.tint.tertiary)

                    /// shimmer text effect
                    // Tip: the shimmer is this SECOND copy of the label, made
                    // visible only through a moving mask. `.mask` keeps the
                    // text wherever the mask is opaque; everything else is
                    // clipped away. So we animate the mask's position and the
                    // label "lights up" wherever the bar currently sits.
                    Text(text)
                        .font(config.textFont)
                        .foregroundStyle(config.tint.tertiary)
                        .mask(alignment: .leading) {
                            GeometryReader {
                                let size = $0.size
                                // `maskWidth` = how wide the lit bar is.
                                // We travel from off-screen left (-maskWidth)
                                // to off-screen right (size.width + maskWidth),
                                // so the total sweep distance pads BOTH ends.
                                let maskWidth: CGFloat = 30
                                let width: CGFloat = size.width + (maskWidth * 2)

                                Rectangle()
                                    .frame(width: maskWidth)
                                    .blur(radius: 5) // soft edges, not a hard line
                                    .rotationEffect(.init(degrees: 15)) // tilt = the classic diagonal sheen
                                    .offset(x: -maskWidth) // start just off the left edge
                                    // Tip: `keyframeAnimator(repeating: true)` drives
                                    // `offset` 0 → width over 3s, forever. We read that
                                    // value back and slide the bar with `.offset(x:)`.
                                    .keyframeAnimator(initialValue: CGFloat.zero, repeating: true) { content, offset in
                                        content.offset(x: offset)
                                    } keyframes: { _ in
                                        LinearKeyframe(width, duration: 3)
                                    }
                            }
                        }
                }
                .fontWeight(.medium)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.leading, config.height / 2)
                /// if using custom iOS27 effect with transparent background
                /// apply distorted blur effect to the text
                // Tip: `.visualEffect` gives you the view's own `proxy`
                // (its geometry) at RENDER time and lets you return a
                // modified view — no extra layout pass, so it's cheap to
                // re-run every frame as the knob drags. The closure captures
                // `[config, isActive, offsetX]` explicitly because it can't
                // touch `self`; capturing the values keeps it a pure function
                // of its inputs, and SwiftUI re-renders whenever they change.
                .visualEffect { [config, isActive, offsetX] content, proxy in
                    // Build the lens rectangle: it sits where the knob is
                    // (x: offsetX) and grows/shrinks with the press state.
                    let scale: CGFloat = isActive ? 1.15 : 0.9
                    let originalFrame = CGRect(x: offsetX, y: 0, width: config.height, height: config.height)
                    // `insetBy` shrinks/grows the rect about its CENTER so the
                    // lens scales in place rather than from a corner.
                    let frame = originalFrame.insetBy(
                        dx: originalFrame.width * (1 - scale) / 2,
                        dy: originalFrame.height * (1 - scale) / 2
                    )

                    // Tip: `.layerEffect` runs a Metal fragment shader
                    // (`liquidLens`, defined in a .metal file) over the
                    // rendered text. We pass the lens position/size as shader
                    // args so the GPU knows WHERE to refract. `maxSampleOffset`
                    // tells SwiftUI how far the shader may read outside each
                    // pixel — needed because refraction samples neighbors.
                    return content
                        .layerEffect(ShaderLibrary.liquidLens(
                            .float2(frame.size),
                            .float(frame.minX),
                            /// refraction amount
                            .float(12),
                            /// depth
                            .float(config.height / 4)
                        ),
                        maxSampleOffset: proxy.size)
                }

                /// Knob (draggable circle for slider)
                Image(systemName: symbol)
                    .font(config.symbolfont)
                    .foregroundStyle(config.tint)
                    .frame(width: config.height, height: config.height)
                    .clipShape(.circle)
                    .keyframeAnimator(
                        initialValue: CGFloat.zero,
                        repeating: config.isSymbolPulsing
                    ) { content, opacity in
                        content.shadow(color: config.tint.opacity(opacity), radius: 5, x: 0, y: 0)
                    } keyframes: { _ in
                        LinearKeyframe(1, duration: 3)
                        LinearKeyframe(0, duration: 3)
                    }
                    // default glass effect - not transparent background
//                     .glassEffect(.clear, in: .circle)
                    // custom iOS27 effect with transparent background
                    .background {
                        Circle()
                            .fill(.clear)
                            .glassEffect(.clear.tint(config.tint.opacity(0.1)), in: .circle)
                            /// inverse mask to only show border effect
                            .mask {
                                Rectangle()
                                    .overlay {
                                        Circle()
                                            .padding(2)
                                            .blur(radius: 2)
                                            .blendMode(.destinationOut)
                                    }
                            }
                    }
                    .contentShape(.circle)
                    .scaleEffect(isActive ? 1.15 : 0.9)
                    .offset(x: offsetX)
                    .highPriorityGesture(
                        DragGesture(minimumDistance: 0)
                            .updating($isActive, body: { _, out, _ in
                                out = true
                            })
                            .onChanged { value in
                                let translation = value.translation.width
                                let cappedOffset = min(max(translation, 0), rect.width - config.height)
                                offsetX = cappedOffset
                                let progress = cappedOffset / (rect.width - config.height)
                                onProgressChanged(progress)
                            }
                            .onEnded { _ in
                                let isCompleted = offsetX == (rect.width - config.height)
                                onFinished(isCompleted)
                                withAnimation(.smooth) {
                                    if isCompleted {
                                        offsetX = rect.width - config.height
                                    } else {
                                        offsetX = 0
                                    }
                                }
                            }
                    )
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.45), value: isActive)
        }
        .frame(height: config.height)
    }

    struct Config {
        var tint: Color
        var height: CGFloat
        var textFont: Font = .title3
        var symbolfont: Font = .title3
        var isSymbolPulsing: Bool = true
    }
}

@available(iOS 26.0, *)
#Preview {
    LiquidGlassCustomSliderDemoView()
}
