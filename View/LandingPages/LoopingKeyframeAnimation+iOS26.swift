//
//  LoopingKeyframeAnimation+iOS26.swift
//  animation
//
//  Created on 5/13/26.
//  Standalone demo (not wired into the app's demo browser; preview-only).
//
//  TODO: Cleanup candidates
//        1. Filename misleads — `+iOS26` suffix, but no
//           `@available(iOS 26.0, *)` and no iOS 26-only APIs
//           (`@Animatable` is iOS 18+, `KeyframeAnimator` and
//           `TimelineView` are iOS 17+). Either rename to
//           `LoopingKeyframeAnimation+iOS18.swift` or add the
//           `@available` gate if iOS 26 is actually intended.
//
//  Learning point
//  ──────────────
//  Three concurrent perpetual animations driven from a single
//  3-second time budget:
//    • Symbol glow that PULSES — radial gradient scales up + fades
//      out, on a `KeyframeAnimator` with a `repeating: true` flag.
//    • Concentric pulse rings — one `Pulse` instance per ring,
//      offset by `delay` so the rings stagger.
//    • Phase rotation — `TimelineView(.periodic(from: now, by: 3))`
//      ticks every 3 seconds, advancing the active phase index
//      which swaps title/subtitle text below.
//  All three derive their timing from the SAME 3-second period so
//  they always feel locked.
//
//  The `@Animatable` `Pulse` struct (line ~223)
//  ────────────────────────────────────────────
//  iOS 18 macro auto-synthesises `AnimatableData` from the
//  struct's stored properties (`scale`, `opacity`). Without it,
//  you'd implement `Animatable` by hand and expose
//  `AnimatablePair<CGFloat, CGFloat>` — six lines of boilerplate
//  the macro replaces with one annotation. The inline comment in
//  the file is intentionally pedagogical; keep it.
//
//  Why `TimelineView(.periodic)` instead of a `Timer`?
//  ───────────────────────────────────────────────────
//  `TimelineView` is driven by SwiftUI's render loop, so the
//  timeline and the keyframe animations stay in sync without
//  manual coordination. A real `Timer` runs on a different clock
//  and would drift relative to the keyframe-driven pulse.
//
//  Key APIs
//  ────────
//  • `@Animatable` (iOS 18+) — auto-synthesises `AnimatableData`.
//  • `KeyframeAnimator(initialValue:repeating:)` — iOS 17+.
//    `repeating: true` makes the keyframe sequence loop forever.
//  • `SpringKeyframe` + `LinearKeyframe` + `CubicKeyframe` —
//    keyframe primitives mixed within a single track for different
//    interpolation feels.
//  • `TimelineView(.periodic(from:by:))` — iOS 17+. Periodic time
//    schedule; gives `context.date` to drive phase math.
//  • `.visualEffect` — drives the offset of the symbol's glow
//    layer per frame.
//
//  How to apply
//  ────────────
//  Reach for this when an empty/idle state needs perpetual,
//  non-distracting motion (loading screens that take >2s, hero
//  illustrations, security-explainer cards). Watch the keyframe
//  durations: every track's TOTAL must equal the period (3s here)
//  or the animations will desync over time.
//
//  See also
//  ────────
//  • View/3DAnimation/Paywall3DAnimation.swift — same `@Animatable`
//    + `@AnimatableIgnored` pattern on a different effect.
//  • View/SpecialAnimationEffects/MetaballAnimation_iOS26.swift —
//    sibling using the same macro for metaball blob math.
//  • OnBoardingiOS26View.swift, PermissionOnboardingIOS26.swift —
//    onboarding-flavor cousins in this folder.
//
import SwiftUI

let mockPhaseData: [LoopOnBoarding.Phase] = [
    .init(
        symbol: "network.badge.shield.half.filled",
        title: "Secure Network Protection",
        description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
    ),
    .init(
        symbol: "faceid",
        title: "Enable Biometric Authentication",
        description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit;"
    ),
    .init(
        symbol: "key.icloud.fill",
        title: "iCloud Key Security",
        description: "Lorem ipsum dolor sit amet..."
    ),
]
struct LoopOnBoardingDemoView: View {
    @State private var showButton: Bool = false
    var body: some View {
        LoopOnBoarding(
            config: .init(showButtons: showButton),
            phases: mockPhaseData
        ) {}
            .onTapGesture {
                showButton.toggle()
            }
    }
}

struct LoopOnBoarding: View {
    var config: Config = .init()
    var phases: [Phase]
    var onButtonClick: () -> Void

    @State private var startDate: Date = .now
    var body: some View {
        ZStack {
            // Guard the divisor: `phaseUpdateAfter` is user-supplied and 0 would
            // crash both `.periodic(by:)` and the integer division below.
            let safePhaseUpdateAfter = max(config.phaseUpdateAfter, 1)
            // 3-SECOND PHASE BUDGET — knob #1 of 2.
            // The literal `3.0` is the per-phase ceiling. Pairs with the keyframe
            // sum below; both must equal each other or the icon bounce will drift
            // out of sync with the symbol swap on each TimelineView tick.
            // `phaseUpdateAfter` is a *multiplier*, not raw seconds: setting it to
            // 2 stretches dwell time to 6s, during which the 3s keyframe loop
            // simply runs twice — letting you slow phases without re-authoring
            // keyframes.
            let timelineDuration = CGFloat(safePhaseUpdateAfter) * 3.0

            // KEY PATTERN — time-driven phase cycling.
            // `.periodic` re-renders the closure every `timelineDuration` seconds.
            // Deriving `index` from `ctx.date` (not @State) means there's no
            // Timer, no mutation, and the view stays a pure function of time.
            TimelineView(.periodic(from: startDate, by: timelineDuration)) { ctx in
                // elapsed seconds → completed phase count → wrap to phases.count
                let diff = Int(startDate.distance(to: ctx.date)) / (safePhaseUpdateAfter * 3)
                let index = diff % phases.count

                ZStack {
                    Image(systemName: phases[index].symbol)
                        .font(.system(size: config.iconSize - 20))
                        .foregroundStyle(config.tint.gradient)
                        // `contentTransition` animates the SF Symbol swap when
                        // `systemName` changes. Without it the symbol pops instantly.
                        .contentTransition(.symbolEffect(.replace.downUp))
                        .frame(width: config.iconSize, height: config.iconSize)
                        // `.keyframeAnimator` modifier — animates an existing view's
                        // value (here: scale). `repeating: true` loops forever.
                        // Contrast with `KeyframeAnimator` (the View) used in pulseRing.
                        .keyframeAnimator(initialValue: 1.0, repeating: true) { content, scale in
                            content
                                .scaleEffect(scale)
                        } keyframes: { _ in
                            let scale = config.iconScale

                            // Keyframe types:
                            //   MoveKeyframe   — instant set, no interpolation
                            //   SpringKeyframe — bouncy, physics-based
                            //   CubicKeyframe  — smooth ease curve
                            //
                            // 3-SECOND PHASE BUDGET — knob #2 of 2.
                            // Durations sum to exactly 3.0 so the keyframe loop
                            // aligns with the TimelineView tick:
                            //   7 × 0.25 (bounce) + 1.25 (hold) = 3.0
                            // `keyframeAnimator(repeating:)` loops independently
                            // of TimelineView, so a mismatched sum would visibly
                            // desync the bounce from the symbol swap.
                            MoveKeyframe(1)
                            /// Bounce effect, total duration 3.0
                            SpringKeyframe(1, duration: 0.25)
                            SpringKeyframe(scale, duration: 0.25)
                            SpringKeyframe(1, duration: 0.25)
                            SpringKeyframe(scale, duration: 0.25)
                            SpringKeyframe(1, duration: 0.25)
                            SpringKeyframe(scale, duration: 0.25)
                            SpringKeyframe(1, duration: 0.25)
                            CubicKeyframe(1, duration: 1.25)
                        }
                        .padding(.bottom, 130)

                    // Only one phase view exists at a time; the `if` toggles
                    // identity so SwiftUI runs insertion/removal transitions.
                    ZStack {
                        ForEach(phases.indices, id: \.self) { phaseIndex in
                            if phaseIndex == index {
                                textContent(phase: phases[phaseIndex])
                                    // Both `.push(from:)` and `.blurReplace` are
                                    // iOS 17+ `Transition`-protocol values, so
                                    // `.combined(with:)` resolves directly.
                                    // Mixing with old `AnyTransition` (e.g. `.asymmetric`)
                                    // requires `AnyTransition(...)` to bridge the two systems.
                                    .transition(
                                        .push(from: .bottom)
                                            .combined(with: .blurReplace)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 15)
                    .padding(.bottom, config.showButtons ? 75 : 10)
                    // Transitions only animate when an ancestor attaches
                    // `.animation(_:value:)` and that value changes. `index`
                    // flips on each TimelineView tick → push+blur fires.
                    .animation(.bouncy(duration: 0.8), value: index)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                }
            }

            Rectangle()
                .foregroundStyle(.clear)
                .overlay {
                    ZStack {
                        /// total duration should be 3.0
                        pulseRing(delay: 0, wait: 1)
                        pulseRing(delay: 0.5, wait: 0.5)
                        pulseRing(delay: 1, wait: 0)
                    }
                }
                .padding(.bottom, 130)
        }.overlay(alignment: .bottom) {
            if config.showButtons {
                Button(action: onButtonClick) {
                    Text(config.buttonTitle)
                        .font(.title3)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .optionalGlassButtonStyle()
                .tint(config.tint)
                .padding(.horizontal, 30)
                .padding(.bottom, 10)
                .transition(.asymmetric(insertion: .push(from: .bottom),
                                        removal: .push(from: .top)))
            }
        }
        .background {
            Circle()
                .fill(config.tint.gradient)
                // `visualEffect` reads geometry (proxy) and applies effects
                // without invalidating layout — cheaper than wrapping in a
                // GeometryReader + `.offset`. Used here to push the glow
                // partly off-screen relative to the circle's own size.
                .visualEffect { content, proxy in
                    content
                        .offset(y: proxy.size.height * 1.2)
                }
                .frame(maxWidth: .infinity, alignment: .bottom)
                .blur(radius: 90)
        }
        .animation(.bouncy(duration: 0.8), value: config.showButtons)
    }

    private func textContent(phase: Phase) -> some View {
        VStack(alignment: .center, spacing: 12) {
            Text(phase.title)
                .font(.title2.bold())
                .lineLimit(1)
            Text(phase.description)
                .font(.callout)
                .fontWeight(.medium)
                .foregroundStyle(.gray)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(height: 130)
    }

    private func pulseRing(delay: CGFloat, wait: CGFloat) -> some View {
        let size = config.iconSize / 2
        // `KeyframeAnimator` (capital K — a View) animates a custom value
        // type and yields it to the builder. Use this when there's no
        // existing view to attach `.keyframeAnimator` to, or when you want
        // to animate multiple properties via one struct (see `Pulse` below).
        return KeyframeAnimator(initialValue: Pulse(), repeating: true) { pulse in
            Circle()
                .stroke(config.pulseTint, lineWidth: config.pulseWidth)
                .frame(width: size * pulse.scale, height: size * pulse.scale)
                .opacity((pulse.scale - 1.0) / 3.0)
                .opacity(pulse.opacity)
        } keyframes: { _ in
            let scale = config.pulseScale

            LinearKeyframe(Pulse(), duration: delay)
            LinearKeyframe(Pulse(scale: scale, opacity: 0), duration: 2)
            LinearKeyframe(Pulse(scale: scale, opacity: 0), duration: wait)
        }
    }

    // `@Animatable` (iOS 18+) auto-synthesizes `AnimatableData` from the
    // struct's stored properties so SwiftUI can interpolate between two
    // `Pulse` values. Pre-iOS 18 you'd implement `Animatable` by hand and
    // expose an `AnimatablePair<CGFloat, CGFloat>`.
    @Animatable
    struct Pulse: Hashable {
        var scale: CGFloat = 1
        var opacity: CGFloat = 1
    }

    struct Config {
        var tint: Color = .blue
        var pulseTint: Color = .blue.opacity(0.65)
        var pulseWidth: CGFloat = 1.3
        var pulseScale: CGFloat = 12

        var iconSize: CGFloat = 100
        var iconScale: CGFloat = 1.25

        var phaseUpdateAfter: Int = 1
        var buttonTitle: String = "Continue"
        var showButtons: Bool = true
    }

    struct Phase: Identifiable {
        private(set) var id: String = UUID().uuidString
        var symbol: String
        var title: String
        var description: String
    }
}

#Preview {
    LoopOnBoardingDemoView()
}
