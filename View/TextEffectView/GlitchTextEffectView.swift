//
//  GlitchTextEffectView.swift
//  animation
//
//  Learning point
//  ──────────────
//  CRT/VHS-style glitch text effect: the text is split into THREE
//  horizontal slices (top / center / bottom), each independently
//  shifted in X with a coloured shadow. Two stacked copies (red + green)
//  produce the classic chromatic-aberration look.
//
//  Three reusable mechanics:
//    1. **Slicing via masks** — three copies of the same `Text`, each
//       masked to show only its third (top / middle / bottom) using a
//       `VStack` of `Rectangle` + `ExtendedSpacer`s. No clipping, no
//       custom shapes.
//    2. **Multi-property keyframe animation** — `GlitchFrame` packs four
//       animatable values (top/center/bottom offsets + shadowOpacity)
//       into nested `AnimatablePair`s so a single `KeyframeAnimator`
//       interpolates all four in lockstep.
//    3. **`@resultBuilder` DSL** — `GlitchFrameBuilder` lets callers
//       declare keyframes as a series of `LinearKeyframe(...)` calls in
//       a trailing closure (same pattern as `@ViewBuilder`).
//
//  The `AnimatablePair` boilerplate
//  ────────────────────────────────
//  SwiftUI's `Animatable` protocol expects a single `animatableData`
//  type, but you often have multiple values to animate together. The
//  fix: nest `AnimatablePair`s into a tree and unpack them in the
//  setter. It's verbose but mechanical:
//
//      AnimatablePair<A, AnimatablePair<B, AnimatablePair<C, D>>>
//
//  Reads like "(A, (B, (C, D)))" — depth = number of values minus one.
//  The `get` packs them; the `set` unpacks via `.first` / `.second`.
//
//  Key APIs
//  ────────
//  • `KeyframeAnimator(initialValue:trigger:content:keyframes:)` — runs
//    the animation each time `trigger` toggles (Boolean ratchet pattern).
//  • `Animatable` + `AnimatablePair` — multi-value frame interpolation.
//  • `@resultBuilder` — DSL for declarative keyframe lists.
//  • `.mask { ... }` with a `VStack` of `Rectangle`+`Spacer` — fast,
//    no-clip way to slice content into thirds.
//  • `.compositingGroup()` — flattens the slices before blending so the
//    coloured shadows from each slice combine cleanly.
//
//  How to apply
//  ────────────
//  Use the `GlitchFrame` + `AnimatablePair` pattern any time you need a
//  KeyframeAnimator to drive several values that must move together.
//  Use the slice-via-mask trick any time you want to address parts of a
//  view (top/middle/bottom strips, left/right halves, quadrants) for
//  independent transforms.
//
//  See also
//  ────────
//  • BorderBeamEffect.swift — same `KeyframeAnimator` foundation,
//    different artistic goal (continuous loop vs. trigger-on-change).
//  • HackerTextView.swift — character-level scramble effect; same
//    "text-as-animation" theme.
//
import SwiftUI

struct GlitchTextEffectDemoView: View {
    /// View properties
    @State private var trigger: (Bool, Bool, Bool) = (false, false, false)
    var body: some View {
        VStack {
            glitchText("Made in Abyss", trigger: trigger.0)
                .font(.system(size: 48, weight: .semibold))

            glitchText("Nanachi", trigger: trigger.1)
                .font(.system(size: 32, design: .rounded))

            glitchText("Season 1", trigger: trigger.2)
                .font(.system(size: 20))

            Button(action: {
                Task {
                    trigger.0.toggle()
                    try? await Task.sleep(for: .seconds(0.6))

                    trigger.1.toggle()
                    try? await Task.sleep(for: .seconds(0.6))

                    trigger.2.toggle()
                }
            }, label: {
                Text("Trigger")
                    .padding(.horizontal, 15)
            })
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .tint(.black)
        }
        .padding()
    }

    @ViewBuilder
    func glitchText(_ text: String, trigger: Bool) -> some View {
        ZStack {
            GlitchTextEffectView(text: text, trigger: trigger, shadow: .red) {
                LinearKeyframe(
                    GlitchFrame(top: -5, center: 0, bottom: 0, shadowOpacity: 0.2),
                    duration: 0.1
                )

                LinearKeyframe(
                    GlitchFrame(top: -5, center: -5, bottom: -5, shadowOpacity: 0.6),
                    duration: 0.1
                )

                LinearKeyframe(
                    GlitchFrame(top: -5, center: -5, bottom: 5, shadowOpacity: 0.8),
                    duration: 0.1
                )

                LinearKeyframe(
                    GlitchFrame(top: 5, center: 5, bottom: 5, shadowOpacity: 0.4),
                    duration: 0.1
                )

                LinearKeyframe(
                    GlitchFrame(top: 5, center: 0, bottom: 5, shadowOpacity: 0.2),
                    duration: 0.1
                )

                LinearKeyframe(
                    GlitchFrame(),
                    duration: 0.1
                )
            }

            GlitchTextEffectView(text: text, trigger: trigger, shadow: .green) {
                LinearKeyframe(
                    GlitchFrame(top: 0, center: 5, bottom: 0, shadowOpacity: 0.2),
                    duration: 0.1
                )

                LinearKeyframe(
                    GlitchFrame(top: 5, center: 5, bottom: 5, shadowOpacity: 0.3),
                    duration: 0.1
                )

                LinearKeyframe(
                    GlitchFrame(top: 5, center: 5, bottom: -5, shadowOpacity: 0.5),
                    duration: 0.1
                )

                LinearKeyframe(
                    GlitchFrame(top: 0, center: 5, bottom: -5, shadowOpacity: 0.6),
                    duration: 0.1
                )

                LinearKeyframe(
                    GlitchFrame(top: 0, center: -5, bottom: 0, shadowOpacity: 0.3),
                    duration: 0.1
                )

                LinearKeyframe(
                    GlitchFrame(),
                    duration: 0.1
                )
            }
        }
    }
}

/// Tip: the multi-value `Animatable` recipe.
/// To animate 4 values together, nest 3 levels of `AnimatablePair`:
///
///     AnimatablePair<top, AnimatablePair<center, AnimatablePair<bottom, shadowOpacity>>>
///
/// Read as a binary tree: `.first` is the leftmost value, then
/// `.second.first`, `.second.second.first`, etc.
/// The interpolation happens automatically — SwiftUI lerps each leaf.
struct GlitchFrame: Animatable {
    var animatableData: AnimatablePair<CGFloat, AnimatablePair<CGFloat, AnimatablePair<CGFloat, CGFloat>>> {
        get {
            .init(top, .init(center, .init(bottom, shadowOpacity)))
        }
        set {
            top = newValue.first
            center = newValue.second.first
            bottom = newValue.second.second.first
            shadowOpacity = newValue.second.second.second
        }
    }

    /// X-offset's
    var top: CGFloat = 0
    var center: CGFloat = 0
    var bottom: CGFloat = 0
    var shadowOpacity: CGFloat = 0
}

/// Result Builder
@resultBuilder
struct GlitchFrameBuilder {
    static func buildBlock(_ components: LinearKeyframe<GlitchFrame>...) -> [LinearKeyframe<GlitchFrame>] {
        components
    }
}

struct GlitchTextEffectView: View {
    var text: String
    /// Config
    var trigger: Bool
    var shadow: Color
    var radius: CGFloat
    var frames: [LinearKeyframe<GlitchFrame>]

    init(text: String, trigger: Bool, shadow: Color = .red, radius: CGFloat = 1, @GlitchFrameBuilder frames: @escaping () -> [LinearKeyframe<GlitchFrame>]) {
        self.text = text
        self.trigger = trigger
        self.shadow = shadow
        self.radius = radius
        self.frames = frames()
    }

    var body: some View {
        KeyframeAnimator(initialValue: GlitchFrame(), trigger: trigger) { value in
            ZStack {
                textView(.top, offset: value.top, opacity: value.shadowOpacity)
                textView(.center, offset: value.center, opacity: value.shadowOpacity)
                textView(.bottom, offset: value.bottom, opacity: value.shadowOpacity)
            }
            .compositingGroup() // not require
        } keyframes: { _ in
            for frame in frames {
                frame
            }
        }
    }

    /// Tip: slice-via-mask pattern.
    /// Each call renders the full Text but masks it to one of three
    /// horizontal thirds: an opaque `Rectangle` in the desired band and
    /// `ExtendedSpacer`s for the bands to hide. Cheaper than custom
    /// `Shape` clipping and animates with the rest of the view.
    @ViewBuilder
    func textView(_ alignment: Alignment, offset: CGFloat, opacity: CGFloat) -> some View {
        Text(text)
            .mask {
                if alignment == .top {
                    VStack(spacing: 0) {
                        // trick to create a view with 1/3 height
                        Rectangle()
                        extendedSpacer()
                        extendedSpacer()
                    }
                } else if alignment == .center {
                    VStack(spacing: 0) {
                        extendedSpacer()
                        Rectangle()
                        extendedSpacer()
                    }
                } else {
                    VStack(spacing: 0) {
                        extendedSpacer()
                        extendedSpacer()
                        Rectangle()
                    }
                }
            }
            .shadow(color: shadow.opacity(opacity), radius: radius, x: offset, y: offset / 2) // use your choice of offset for y, input a new value if preferred
            .offset(x: offset)
    }

    @ViewBuilder
    func extendedSpacer() -> some View {
        Spacer(minLength: /*@START_MENU_TOKEN@*/0/*@END_MENU_TOKEN@*/)
            .frame(maxHeight: .infinity)
    }
}

#Preview {
    GlitchTextEffectDemoView()
}
