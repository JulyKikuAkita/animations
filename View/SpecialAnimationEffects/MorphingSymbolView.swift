//
//  MorphingSymbolView.swift
//  animation
//
//  Learning point
//  ──────────────
//  Cleaner per-symbol metaball morph driven by `KeyframeAnimator`:
//  pass a new `symbol` name and the current SF Symbol "blobs" out
//  while the next one "blobs" in, with the swap happening at the
//  precise midpoint of the keyframe blur curve.
//
//  Why this is more reliable than `MorphingView`'s timer approach
//  ──────────────────────────────────────────────────────────────
//  `MorphingView` uses a 100Hz `Timer.publish` and increments
//  `blurRadius` manually, swapping the image when blurRadius
//  rounds to a magic number. Works, but the swap can race the
//  timer and visibly stutter under load. This file uses a
//  `KeyframeAnimator(initialValue: 0, trigger: ...)` with two
//  cubic keyframes:
//
//      CubicKeyframe(config.radius, duration: keyFrameDuration)
//      CubicKeyframe(0, duration: keyFrameDuration)
//
//  → the blur ramps 0 → `radius` → 0. We attach
//  `.onChange(of: radius) { newValue in ... }` and swap the symbol
//  when `newValue.rounded() == config.radius` — i.e. at the EXACT
//  moment the blur is at its peak (mid-morph). Frame-perfect; no
//  manual timing needed.
//
//  Three reusable mechanics
//  ────────────────────────
//    1. **`Canvas` + `alphaThreshold` mask** — same gooey-edge
//       trick as the metaball file: a blurred SF Symbol drawn into
//       a Canvas with `addFilter(.alphaThreshold(min: 0.4, color:))`
//       gives crisp blob silhouettes during the blur peak.
//    2. **`KeyframeAnimator(trigger:)`** — re-fires the keyframe
//       sequence every time `trigger` toggles. We toggle on each
//       new `symbol` value, replacing the older "increment a
//       state and watch it" loops.
//    3. **Mid-curve symbol swap** — `nextSymbol` is staged on
//       `onChange(of: symbol)`; the actual image swap happens
//       inside the keyframe's `onChange(of: radius)` exactly when
//       blur peaks. So the user never sees the symbol pop in or
//       out — only the gooey threshold mask fully obscures it
//       during the swap.
//
//  Why `Canvas` + filter vs a Metal shader
//  ───────────────────────────────────────
//  Canvas with `.alphaThreshold` works on iOS 17+ and needs zero
//  Metal code. For iOS 18+ projects with custom shaders, the
//  Metal-shader morph in `[[MetaballAnimation_iOS26]]` gives
//  finer control over the threshold edge and is a touch cheaper
//  per frame. For typical icon-sized morphs, the Canvas approach
//  is plenty fast.
//
//  Key APIs
//  ────────
//  • `KeyframeAnimator(initialValue:trigger:content:keyframes:)` —
//    re-fire on each trigger toggle.
//  • `CubicKeyframe(target, duration:)` — eased ramp.
//  • `Canvas + addFilter(.alphaThreshold(min:color:))` — gooey
//    silhouette mask.
//  • `withAnimation(config.symbolAnimation) { displayingSymbol = nextSymbol }` —
//    extra spring on the actual image swap so the new symbol
//    settles instead of teleporting.
//
//  How to apply
//  ────────────
//  Use whenever you need a gooey symbol/icon transition driven by
//  a single trigger value. The "swap mid-keyframe-peak" pattern
//  generalises to ANY effect where content needs to swap at the
//  invisible apex of a transformation (max blur, max scale, etc).
//
//  See also
//  ────────
//  • MorphingView.swift — pre-iOS-17 timer-driven version of the
//    same idea.
//  • MetaballAnimation_iOS26.swift — Metal-shader alternative.
//  • AlphaThreshold.metal — the shader those use.
//

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
