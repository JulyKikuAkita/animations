//
//  BorderBeamEffect.swift
//  animation
//
//  Created on 5/2/26.
//
// A `.borderBeam(...)` modifier that animates a moving glow around a
// rounded rectangle's border (think "AI thinking" / Raycast input / Gemini
// glow).
//
// Learning points
// ───────────────────────────────────────────────────────────────────────
// 1. Continuous animation driver (`KeyframeAnimator`, iOS 17+).
//    A single `LinearKeyframe(1, duration: 2.5)` driven by
//    `repeating: true` gives us a 0→1 value that restarts every 2.5s. We
//    multiply by 360 to get a rotation angle. No `Timer`, no
//    `CADisplayLink`, no `@State` ticker — the framework handles the
//    redraws. See the "Deep dive — KeyframeAnimator" section below for
//    when to reach for it vs. other animation APIs.
//
// 2. Rotating gradient = moving "beam".
//    An `AngularGradient` whose `startAngle`/`endAngle` depend on the
//    animator's value sweeps a `[.clear, border, .clear]` arc around the
//    circle. That arc is what becomes the glow slice.
//
// 3. `@ViewBuilder` + extension View = clean call site.
//    Callers write `.borderBeam(border: .primary, beam: [...], ...)` with
//    the usual SwiftUI modifier chaining. See `BorderBeamTextFieldView`
//    for concrete usage on both a card and a circular button.
//
// ───────────────────────────────────────────────────────────────────────
// Deep dive — KeyframeAnimator (why, when, and alternatives)
// ───────────────────────────────────────────────────────────────────────
//
// What it is
//   `KeyframeAnimator(initialValue:repeating:content:keyframes:)` runs the
//   `content` closure on every frame with a *value* interpolated between
//   keyframes you describe declaratively. It's iOS 17+.
//
// The keyframe types you can mix and match
//   • `LinearKeyframe(target, duration:)`  — linear ramp to `target`
//   • `SpringKeyframe(target, duration:, spring:)` — spring physics
//   • `CubicKeyframe(target, duration:)`   — cubic-bezier easing
//   • `MoveKeyframe(target)`               — instant jump, no interpolation
//   You chain several of these in the `keyframes:` closure to describe a
//   timeline: "hold here, spring to here, linearly ramp to there…"
//
// Why use it (what other APIs can't do as cleanly)
//   • Multi-stage animation with *different* curves per stage.
//   • Animating multiple properties on independent timelines in parallel
//     (pass a struct as `initialValue`; provide a `KeyframeTrack` per
//     keyPath — each track has its own keyframes).
//   • Value-driven rendering: the animator hands you the interpolated
//     value directly, so you draw based on it without a `@State` mirror.
//   • Looping continuous animations via `repeating: true`.
//
// When NOT to reach for it
//   • Simple two-state transitions → plain `.animation(...)` /
//     `withAnimation { }` is shorter.
//   • You just want wall-clock time → `TimelineView(.animation)` and
//     compute your own value.
//   • Pre-iOS-17 support required → `@State` + `.animation(...)
//     .repeatForever(autoreverses: false)`.
//
// Decision table
//
//    You want...                                        Use
//    ────────────────────────────────────────────────   ──────────────────
//    Animate between 2 states with one curve            .animation / withAnimation
//    Raw elapsed time, compute values manually          TimelineView(.animation)
//    Multi-stage animation (different curves per leg)   KeyframeAnimator
//    Many properties animating in parallel w/ own timing KeyframeAnimator + struct
//    Continuous loop with potential for complex timing  KeyframeAnimator(repeating: true)
//    Need to support iOS 16 or older                    @State + repeatForever
//
// How we use it here
//   This file uses the simplest possible shape: one `LinearKeyframe` in a
//   repeating animator. For a plain linear loop that alone is arguably
//   overkill — `TimelineView` would work. But this form gives us room to
//   grow without rewiring:
//     • Swap `LinearKeyframe` → `SpringKeyframe` → beam pulses.
//     • Add a second keyframe at a different value → beam accelerates
//       into the corners, eases out.
//     • Bind a second property on the animator's struct → scale, opacity,
//       whatever, all on the same clock.
//   All of those changes touch only the `keyframes:` closure. That's the
//   payoff: timing lives in one declarative block, isolated from state
//   and view layout.
//
// ───────────────────────────────────────────────────────────────────────
// Deep dive — the two-mask technique (see `borderBeamView()` below)
// ───────────────────────────────────────────────────────────────────────
//
// We start with a `RoundedRectangle` filled with the full colorful
// `beamGradient`. Drawn alone, that's a fully-coloured rounded rect —
// too much colour, everywhere. We need to whittle it down to
// "a colourful slice that moves around the edge." Each `.mask` chips
// away on a different axis. Masks compose by **intersection**: a pixel
// is visible only where *every* mask is opaque.
//
//   Mask 1 — "keep only the border region"  (static shape mask)
//
//     .mask {
//         Rectangle()                       // opaque canvas
//             .overlay {
//                 RoundedRectangle(...)
//                     .blur(radius: beamBlur)       // soft inner edge
//                     .blendMode(.destinationOut)   // eraser
//             }
//     }
//
//   The overlayed rounded rectangle *erases* itself from the canvas
//   (`.destinationOut`), leaving a soft-edged donut: opaque on the border,
//   transparent in the middle. Applied as a mask, this confines the
//   colourful fill to the border region. If we stopped here we'd have a
//   static coloured ring. `blur` (not `padding`) is used for the falloff
//   because blur gives a natural antialiased gradient instead of a hard
//   edge.
//
//   Mask 2 — "keep only the current rotating slice"  (animated mask)
//
//     .mask {
//         RoundedRectangle(...)
//             .fill(borderGradient)        // AngularGradient [.clear, colour, .clear]
//             .blur(radius: beamBlur / 1.5)
//             .padding(-beamBlur * 2)      // extend past bounds
//     }
//
//   `borderGradient` is transparent except in a narrow arc that rotates
//   with the animator. Applied as a mask, it restricts visibility to
//   whichever part of the border the arc is currently over. Negative
//   padding extends the mask beyond the shape so the blurred leading/
//   trailing edges don't clip at the rounded corners.
//
//   Combined:
//     fill  ∩  "border region"  ∩  "current rotating arc"
//         =  a soft-edged coloured slice that travels around the border
//
//   Why two masks instead of one? Each has one job:
//     Mask 1 — *where* on the shape the beam can ever appear (static).
//     Mask 2 — *when* / which part of the border shows (animated).
//   Splitting them means only Mask 2 needs to redraw per frame; Mask 1
//   is cacheable. Same "separate what moves from what doesn't" principle
//   as the source/overlay pattern in PinchZoom.swift.
// ───────────────────────────────────────────────────────────────────────

import SwiftUI

extension View {
    @ViewBuilder
    func borderBeam(
        border: Color,
        hideFadeBorder: Bool = true,
        beam: [Color],
        beamBlur: CGFloat,
        cornerRadius: CGFloat,
        isEnabled: Bool = true
    ) -> some View {
        modifier(
            BorderBeamEffect(
                border: border,
                hideFadeBorder: hideFadeBorder,
                beam: beam,
                beamBlur: beamBlur,
                cornerRadius: cornerRadius,
                isEnabled: isEnabled
            )
        )
    }
}

/// Using keyframe Animator to animate the border beam effect
struct BorderBeamEffect: ViewModifier {
    var border: Color
    var hideFadeBorder: Bool
    var beam: [Color]
    var beamBlur: CGFloat
    var cornerRadius: CGFloat
    var isEnabled: Bool
    func body(content: Content) -> some View {
        content
            .background {
                if isEnabled {
                    borderBeamView()
                }
            }
    }

    private func borderBeamView() -> some View {
        ZStack {
            if !hideFadeBorder {
                /// faded border
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(border.tertiary, lineWidth: 0.6)
            }

            KeyframeAnimator(initialValue: 0.0, repeating: true) { value in
                let rotation = value * 360
                let borderGradient = AngularGradient(
                    colors: [.clear, border, .clear],
                    center: .center,
                    startAngle: .degrees(140 + rotation),
                    endAngle: .degrees(270 + rotation)
                )
                let beamGradient = LinearGradient(
                    colors: beam,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                /// bream gradient
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(beamGradient)
                    /// inverse masking to show only limited amount of beam gradient
                    .mask {
                        Rectangle()
                            .overlay {
                                RoundedRectangle(cornerRadius: cornerRadius)
                                    /// using blur instead of padding to get smooth ending
                                    .blur(radius: beamBlur)
                                    .blendMode(.destinationOut)
                            }
                    }
                    .mask {
                        /// 2nd mask to sync with border effect
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(borderGradient)
                            .blur(radius: beamBlur / 1.5)
                            .padding(-beamBlur * 2)
                    }

                /// border gradient
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderGradient, lineWidth: 0.6)
            } keyframes: { _ in
                LinearKeyframe(1, duration: 2.5)
            }
        }
        .padding(0.5)
    }
}

#Preview {
    BorderBeamTextFieldDemoView()
}
