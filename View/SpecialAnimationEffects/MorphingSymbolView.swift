//
//  MorphingSymbolView.swift
//  animation
//  iOS 18
import SwiftUI

struct MorphingSymbolView: View {
    var symbol: String
    var config: MorphingSymbolConfig
    /// View Properties
    @State private var trigger: Bool = false
    @State private var displayingSymbol: String = ""
    @State private var nextSymbol: String = ""
    var body: some View {
        Canvas { ctx, size in
            ctx.addFilter(.alphaThreshold(min: 0.4, color: config.foregroundColor))

            if let renderedImage = ctx.resolveSymbol(id: 0) {
                ctx.draw(renderedImage, at: CGPoint(x: size.width / 2, y: size.height / 2))
            }
        } symbols: {
            imageView()
                .tag(0)
        }
        .frame(width: config.frame.width, height: config.frame.height)
        .onChange(of: symbol) { _, newValue in
            trigger.toggle()
            nextSymbol = newValue
        }
        .task {
            guard displayingSymbol == "" else { return }
            displayingSymbol = symbol
        }
    }

    @ViewBuilder
    func imageView() -> some View {
        KeyframeAnimator(
            initialValue: CGFloat.zero, trigger: trigger
        ) { radius in
            Image(systemName: displayingSymbol == "" ? symbol : displayingSymbol)
                .font(config.font)
                .blur(radius: radius)
                .frame(width: config.frame.width, height: config.frame.height)
                .onChange(of: radius) { _, newValue in
                    /// morph effect begins at 0 to config radius then ends at 0,
                    /// when the value == config.radius, it's at the middle thus a perfect timing to switch symbol
                    if newValue.rounded() == config.radius {
                        /// Animating Symbol Change
                        withAnimation(config.symbolAnimation) {
                            displayingSymbol = nextSymbol
                        }
                    }
                }
        } keyframes: { _ in
            CubicKeyframe(config.radius, duration: config.keyFrameDuration)
            CubicKeyframe(0, duration: config.keyFrameDuration)
        }
    }

    struct MorphingSymbolConfig {
        var font: Font
        var frame: CGSize
        var radius: CGFloat /// important to achieve morphing effect
        var foregroundColor: Color
        var keyFrameDuration: CGFloat = 0.4
        var symbolAnimation: Animation = .smooth(duration: 0.5, extraBounce: 0)
    }
}

#Preview {
    MorphingSymbolView(
        symbol: "shazam.logo.fill",
        config: .init(
            font: .system(size: 100, weight: .bold),
            frame: CGSize(width: 250, height: 200),
            radius: 15,
            foregroundColor: .black
        )
    )
}
