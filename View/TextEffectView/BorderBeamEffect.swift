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
//
// Do you actually need both masks?
//   No. The two-mask version buys you *radial falloff* — the glow fades
//   softly inward from the edge (the Siri / Raycast halo look). If you
//   just want a crisp colorful beam sliding around the border, simpler
//   forms work:
//
//     (a) one mask, stroke instead of fill
//         RoundedRectangle(cornerRadius: cornerRadius)
//             .stroke(beamGradient, lineWidth: 3)
//             .mask {
//                 RoundedRectangle(cornerRadius: cornerRadius)
//                     .stroke(borderGradient, lineWidth: 3)
//             }
//             .blur(radius: beamBlur / 3)
//
//     (b) zero masks — bake the arc into the stroke's gradient
//         let rotating = AngularGradient(
//             colors: [.clear, .indigo, .blue, .red, .yellow, .clear],
//             center: .center,
//             startAngle: .degrees(rotation),
//             endAngle: .degrees(rotation + 120))
//         RoundedRectangle(cornerRadius: cornerRadius)
//             .stroke(rotating, lineWidth: 3)
//             .blur(radius: beamBlur / 2)
//             .clipShape(RoundedRectangle(cornerRadius: cornerRadius)) // cut blur ouside
//
//   Trade-off: (a) and (b) give you a band of fixed thickness instead of
//   a halo that dissolves inward. If you don't need the halo, reach for
//   (b) — it's the form I'd write from scratch. The current two-mask
//   version is only "load-bearing" when the halo falloff *is* the look
//   you're after.
// ───────────────────────────────────────────────────────────────────────

import SwiftUI

// Four rendering techniques, increasing in complexity and aesthetic cost.
// See the "Deep dive — the two-mask technique" section in this file's
// header for the full comparison + trade-offs.
enum BorderBeamStyle: String, CaseIterable {
    /// Zero masks. Beam colours baked directly into a rotating
    /// `AngularGradient` stroke, clipped to the rounded rect so the blur
    /// stays inside. Simplest. No halo falloff.
    case simple
    /// Same as `.simple` but without the clip — the blur bleeds outward
    /// past the shape. Shown for visual comparison against `.simple`.
    case simpleUnclipped
    /// One mask. Rainbow `LinearGradient` stroke, masked by a rotating
    /// angular-gradient stroke that reveals only the current arc.
    /// Colourful beam, no inward halo.
    case singleMask
    /// Two masks (fill + inverse-border-mask + rotating-arc-mask).
    /// Heaviest aesthetic: rainbow ambient halo that fades inward from
    /// the edge, with the arc acting as a moving spotlight on top.
    case masks
}

private extension View {
    /// Apply `clipShape` only when the condition is true. Used to toggle
    /// whether an effect's blur stays confined to the shape.
    @ViewBuilder
    func clipShapeIf(_ condition: Bool, _ shape: some Shape) -> some View {
        if condition { clipShape(shape) } else { self }
    }
}

extension View {
    @ViewBuilder
    func borderBeam(
        border: Color,
        hideFadeBorder: Bool = true,
        beam: [Color],
        beamBlur: CGFloat,
        cornerRadius: CGFloat,
        isEnabled: Bool = true,
        style: BorderBeamStyle = .simple
    ) -> some View {
        modifier(
            BorderBeamEffect(
                border: border,
                hideFadeBorder: hideFadeBorder,
                beam: beam,
                beamBlur: beamBlur,
                cornerRadius: cornerRadius,
                isEnabled: isEnabled,
                style: style
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
    var style: BorderBeamStyle
    func body(content: Content) -> some View {
        content
            .background {
                if isEnabled {
                    switch style {
                    case .simple:
                        borderBeamView(clipped: true)
                    case .simpleUnclipped:
                        borderBeamView(clipped: false)
                    case .singleMask:
                        borderBeamSingleMaskView()
                    case .masks:
                        borderBeamMasksView()
                    }
                }
            }
    }

    /// Shared scaffold for every style: faded outline (optional) + a
    /// repeating `KeyframeAnimator` that hands the current rotation (0-360°)
    /// to each variant's drawing closure.
    ///
    /// Each `borderBeam*View` function below supplies *only* its unique
    /// beam-drawing logic; ZStack, fade border, animator and padding live
    /// in one place so swapping timing or outline affects all styles at
    /// once.
    private func borderBeamScaffold(
        @ViewBuilder draw: @escaping (_ rotation: Double) -> some View
    ) -> some View {
        ZStack {
            if !hideFadeBorder {
                /// faded static outline
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(border.tertiary, lineWidth: 0.6)
            }

            // Tip: simplest possible KeyframeAnimator shape:
            //   • One LinearKeyframe(1, duration: 2.5) → value ramps 0→1.
            //   • `repeating: true` restarts when it hits 1.
            //   • `value * 360` maps the 0–1 timeline onto 0–360° rotation.
            // No Timer / @State / CADisplayLink — SwiftUI owns the cadence.
            KeyframeAnimator(initialValue: 0.0, repeating: true) { value in
                draw(value * 360)
            } keyframes: { _ in
                LinearKeyframe(1, duration: 2.5)
            }
        }
        .padding(0.5)
    }

    /// Zero-mask variant: rainbow arc baked into the rotating
    /// `AngularGradient`. `clipped` controls whether the blur stays inside
    /// the rounded rect (`.simple`) or bleeds outward (`.simpleUnclipped`).
    private func borderBeamView(clipped: Bool = true) -> some View {
        borderBeamScaffold { rotation in
            let borderGradient = AngularGradient(
                colors: [.clear] + beam + [.clear],
                center: .center,
                startAngle: .degrees(140 + rotation),
                endAngle: .degrees(270 + rotation)
            )

            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(borderGradient, lineWidth: 2)
                .blur(radius: beamBlur / 2)
                // Only visible difference between `.simple` and `.simpleUnclipped`.
                .clipShapeIf(clipped, RoundedRectangle(cornerRadius: cornerRadius))

            /// thin static outline at current arc
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(borderGradient, lineWidth: 0.6)
        }
    }

    /// One-mask variant: a rainbow stroke made visible only where the
    /// rotating angular-gradient arc is opaque. Intermediate between
    /// `simple` (no masks) and `masks` (two masks + radial halo).
    private func borderBeamSingleMaskView() -> some View {
        borderBeamScaffold { rotation in
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

            /// Full colourful stroke, masked to show only where the
            /// rotating arc mask is opaque.
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(beamGradient, lineWidth: 2)
                .mask {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(borderGradient, lineWidth: 2)
                        .blur(radius: beamBlur / 1.5)
                        .padding(-beamBlur * 2)
                }
                .blur(radius: beamBlur / 3)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))

            /// thin arc outline
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(borderGradient, lineWidth: 0.6)
        }
    }

    /// Two-mask variant: rainbow fill + inverse-border mask (radial halo)
    /// + rotating-arc mask (spotlight). See the deep dive in the file
    /// header for the full walkthrough.
    private func borderBeamMasksView() -> some View {
        borderBeamScaffold { rotation in
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

            /// beam gradient
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

            /// thin arc outline
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(borderGradient, lineWidth: 0.6)
        }
    }
}

#Preview {
    BorderBeamTextFieldDemoView()
}
