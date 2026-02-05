//
//  Paywall3DAnimation.swift
//  animation
//
//  Created on 2/4/26.

import SwiftUI

struct Paywall3DEffect: View {
    var symbols: [String]
    var symbolFont: Font
    var tint: Color
    /// View Properties
    @State private var trim: CGFloat = 0
    @State private var rotation: CGFloat = 0
    @State private var isAnimating: Bool = false
    var body: some View {
        Rectangle()
            .foregroundStyle(.clear)
            .modifier(
                Paywall3DEffectModifier(
                    symbols: symbols,
                    symbolFont: symbolFont,
                    tint: tint,
                    trim: trim,
                    rotation: rotation
                )
            )
            .task {
                guard !isAnimating else { return }
                isAnimating = true
                try? await Task.sleep(for: .seconds(0.1))
                withAnimation(.easeInOut(duration: 1.5)) {
                    trim = 1
                }
                try? await Task.sleep(for: .seconds(0.5))
                withAnimation(.linear(duration: 15).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}

/// Use view modifier to ensure trim/rotation properties conform to Animatable protocol
@Animatable
private struct Paywall3DEffectModifier: ViewModifier {
    @AnimatableIgnored var symbols: [String]
    @AnimatableIgnored var symbolFont: Font
    @AnimatableIgnored var tint: Color
    var trim: CGFloat = 0
    var rotation: CGFloat = 0
    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader {
                    let size = $0.size
                    let circleSize = min(size.width, size.height)
                    let dashLength = (CGFloat.pi * circleSize) / CGFloat(symbols.count * 2)
                    let dashPhase = -dashLength / 2
                    let strokeStyle = StrokeStyle(lineWidth: 3,
                                                  dash: [dashLength],
                                                  dashPhase: dashPhase)
                    ZStack {
                        Circle()
                            .trim(from: 0, to: trim)
                            .stroke(tint, style: strokeStyle)
                            .rotationEffect(.init(degrees: rotation))
                            .rotation3DEffect(
                                .init(degrees: 62),
                                axis: (x: 1, y: 0, z: 0),
                                anchor: .center,
                                perspective: 0
                            )
                            .rotation3DEffect(
                                .init(degrees: -20),
                                axis: (x: 0, y: 0, z: 1),
                                anchor: .center,
                                perspective: 0
                            )
                        /// note:  do not apply the same rotation3DEffect to the icons that will scale them to not UX acceptable state
                        ///  we need to manually calculate the rotation degrees
                        ZStack {
                            ForEach(symbols.indices, id: \.self) { index in
                                let radius = circleSize / 2
                                let angle = (CGFloat(index) / CGFloat(symbols.count)) * 360 + rotation
                                let angleInRadians = (CGFloat.pi * angle) / 180
                                /// calculate x & y offset for the angels manually
                                let rotation3D = cos((62 * CGFloat.pi) / 180)
                                let x = cos(angleInRadians) * radius
                                let y = sin(angleInRadians) * radius * rotation3D

                                /// animate the trim value -> apply scale effect to each element in order
                                let start = CGFloat(index) / CGFloat(symbols.count)
                                let end = CGFloat(index + 1) / CGFloat(symbols.count)
                                let scaleProgress = max(min((trim - start) / (end - start), 1), 0)

                                /// individual icon rotation
                                let iconRotation = rotation + CGFloat(index * 10)

                                Image(systemName: symbols[index])
                                    .font(symbolFont)
                                    .foregroundStyle(tint)
                                    /// adding drop shadows
                                    .shadow(color: tint.opacity(0.15), radius: 2, x: 1, y: 2)
                                    .shadow(color: tint.opacity(0.1), radius: 8, x: 4, y: 8)
                                    .scaleEffect(scaleProgress)
                                    /// individual icon rotation
                                    .rotationEffect(.init(degrees: iconRotation))
                                    .rotation3DEffect(
                                        .init(degrees: iconRotation),
                                        axis: (x: 0, y: 1, z: 0),
                                        anchor: .center,
                                        perspective: 0
                                    )
                                    /// reverse Z rotation for the icons
                                    .rotationEffect(.init(degrees: 20))
                                    .offset(x: x, y: y)
                            }
                        }
                        /// z is typical rotation so safe to apply it to icons
                        .rotationEffect(.init(degrees: -20))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
    }
}

#Preview {
    let symbols: [String] = [
        "photo",
        "square.arrowtriangle.4.outward",
        "inset.filled.pano",
        "square.and.arrow.up.fill",
        "pawprint",
    ]
    Paywall3DEffect(symbols: symbols, symbolFont: .title, tint: .primary)
        .frame(height: 300)
}
