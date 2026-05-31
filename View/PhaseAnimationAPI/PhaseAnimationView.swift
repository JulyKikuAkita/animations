//
//  PhaseAnimationView.swift
//  animation
//
//  Standalone demo (not wired into the app's demo browser; preview-only).
//  iOS 17+ — `PhaseAnimator` is the gating API.
//
//  TODO: Light cleanup
//        `.navigationBarTitleDisplayMode(.inline)` in the `#Preview`
//        is the pre-iOS 26 spelling. The iOS 26 replacement is
//        `.toolbarTitleDisplayMode(.inline)` (used in
//        `View/Keyboard/AnimatedKeyboard+iOS26.swift`). Both still
//        work; if the project standardises on the newer API, swap.
//
//  Learning point
//  ──────────────
//  Auto-cycling slideshow over `OSInfo.allCases` powered by
//  `PhaseAnimator`. Each phase advances every ~1.5s; the active
//  case's icon and label fade through two DIFFERENT transitions
//  simultaneously:
//    • Icon — `.blurReplace(.downUp)`: the old icon blurs out
//      downward and the new one blurs in upward.
//    • Label — `.push(from: .bottom)`: the new label slides in
//      from below; the old one pushes up and out.
//  Two transitions on two children of the same phase. Reading them
//  side-by-side is the demo's main pedagogy.
//
//  The `isAnimationEnabled` workaround (line ~8)
//  ─────────────────────────────────────────────
//  Without the `if isAnimationEnabled` gate, the FIRST `PhaseAnimator`
//  child appears via SwiftUI's default insertion transition, which
//  on iOS 17 reads as a slide from top-left for ZStack-laid content.
//  Wrapping in a Bool that flips to `true` inside `.task` bypasses
//  the initial-insert: the PhaseAnimator and its children are
//  installed AFTER the first frame, so SwiftUI doesn't run the
//  insert transition. Keep the workaround unless you've verified
//  on a current iOS that the bug is gone.
//
//  The `ZStack { ForEach { if isSame { ... } } }` pattern
//  ──────────────────────────────────────────────────────
//  Why iterate ALL cases inside each phase, then conditionally
//  show the matching one? Because `.transition(...)` needs the
//  view to APPEAR/DISAPPEAR for the transition to fire. Just
//  rendering `Image(systemName: info.symbolImage)` directly with
//  `.transition(...)` wouldn't transition on phase change — it
//  would just swap the symbol in place. The ForEach + isSame
//  guard creates a real insert/remove every phase, which is what
//  the transition modifier needs.
//
//  Key APIs
//  ────────
//  • `PhaseAnimator(_:content:animation:)` — iOS 17+. Auto-cycles
//    a sequence; the closure receives the current phase. The
//    `animation:` trailing closure can return a different curve
//    per phase — here we return one constant curve with a 1.5s
//    delay so each slide dwells before the next.
//  • `.transition(.blurReplace(.downUp))` — iOS 17+ blur swap;
//    `.downUp` controls direction (out-down, in-up).
//  • `.transition(.push(from: .bottom))` — directional push that
//    plays nicely with `.clipped()` on the parent.
//  • `.interpolatingSpring(.bouncy(duration:extraBounce:))` —
//    spring with explicit duration; pairs cleanly with `.delay()`.
//
//  How to apply
//  ────────────
//  Reach for `PhaseAnimator` whenever a UI element needs to cycle
//  through a fixed sequence WITHOUT user input — feature carousels,
//  empty-state mascots, splash screens. If you need user-driven
//  state instead, `.phaseAnimator(_:content:trigger:)` exists for
//  that. The transition-via-ForEach trick generalises to any
//  PhaseAnimator child that should animate on phase change.
//
//  See also
//  ────────
//  • Model/OSInfo.swift — the data source.
//  • View/SpecialAnimationEffects/* — other animation patterns
//    (PhaseAnimator vs. KeyframeAnimator vs. @Animatable).
//
import SwiftUI

struct PhaseAnimationViewDemo: View {
    @State private var isAnimationEnabled: Bool = false /// workaround to avoid new image slide in from topLeft
    var body: some View {
        ZStack {
            if isAnimationEnabled {
                PhaseAnimator(OSInfo.allCases) { info in
                    VStack(spacing: 10) {
                        ZStack {
                            ForEach(OSInfo.allCases, id: \.rawValue) { osInfo in
                                let isSame = osInfo == info

                                if isSame {
                                    Image(systemName: osInfo.symbolImage)
                                        .font(.system(size: 100, weight: .ultraLight, design: .rounded))
                                        .transition(.blurReplace(.downUp))
                                }
                            }
                        }
                        .frame(height: 120)

                        VStack(spacing: 10) {
                            Text("Available On")
                                .font(.callout)
                                .foregroundStyle(.secondary)

                            ZStack {
                                ForEach(OSInfo.allCases, id: \.rawValue) { osInfo in
                                    let isSame = osInfo == info

                                    if isSame {
                                        Text(osInfo.rawValue)
                                            .font(.largeTitle)
                                            .fontWeight(.semibold)
                                            .fontDesign(.rounded)
                                            .transition(.push(from: .bottom))
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .clipped()
                        }
                    }
                } animation: { _ in
                    /// delay between each slide
                    .interpolatingSpring(.bouncy(duration: 1, extraBounce: 0)).delay(1.5)
                }
            }
        }
        .task {
            isAnimationEnabled = true
        }
    }
}

#Preview {
    NavigationStack {
        PhaseAnimationViewDemo()
            .navigationTitle("Phase Animator")
            .navigationBarTitleDisplayMode(.inline)
    }
}
