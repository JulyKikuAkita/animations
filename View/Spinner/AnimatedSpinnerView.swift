//
//  AnimatedSpinnerView.swift
//  animation
//
//  ⚠️  REUSABLE HELPER, NOT A STANDALONE DEMO. Consumed by
//      `View/Button/SpinnerButton.swift:~103` as the spinner inside
//      a multi-stage transaction button. Renaming or removing
//      requires updating that call site.
//
//  TODO: Cleanup
//        Public parameter is misspelled: `linedWidth` should be
//        `lineWidth`. The call site in `SpinnerButton.swift` passes
//        `linedWidth: 4`, so a rename is a 2-file change. Worth doing
//        — every future caller will copy the typo otherwise.
//
//  Learning point
//  ──────────────
//  Tiny circular spinner with a deliberately IRREGULAR rotation —
//  it doesn't spin at a constant rate. Two `withAnimation` calls
//  drive two `rotationEffect` modifiers stacked on the same arc:
//    • `rotation`        — 0.7s per revolution, starts immediately.
//    • `extraRotation`   — 1.0s per revolution, starts AFTER a 1s delay.
//  Composed via `.compositingGroup()`, the result is a spinner whose
//  apparent angular velocity wobbles — much more "alive" than a
//  single constant spin. The dim background ring (line 15) is the
//  same `Circle` at 30% opacity so the moving arc has a track to
//  follow.
//
//  Why a 0.3-trim arc, not a half-circle?
//  ──────────────────────────────────────
//  `Circle().trim(from: 0, to: 0.3)` keeps about 108° of the circle
//  visible — long enough to read as motion, short enough that the
//  two-rotation overlay never produces a "fully drawn" frame.
//
//  Key APIs
//  ────────
//  • `Circle().trim(from:to:).stroke(_, style:)` — the standard
//    arc-segment idiom; `.lineCap: .round` softens the leading edge.
//  • `withAnimation(.linear.repeatForever(autoreverses: false))` ×2
//    — two parallel infinite loops. `autoreverses: false` is
//    critical; with reverses you'd get a back-and-forth wobble
//    instead of continuous rotation.
//  • `.compositingGroup()` — ensures both rotations apply to the
//    SAME rendered layer; without it, SwiftUI may flatten the
//    transforms and the wobble effect collapses.
//
//  How to apply
//  ────────────
//  Drop in anywhere a stock `ProgressView()` reads as too
//  mechanical. The `tint` parameter gets you brand-coloured spinners
//  in one line. Pair with `SpinnerButton`-style state machines for
//  multi-phase async work.
//
//  See also
//  ────────
//  • View/Button/SpinnerButton.swift — the consumer; demonstrates
//    swapping this spinner in/out via `@State isLoading`.
//
import SwiftUI

struct AnimatedSpinnerView: View {
    var tint: Color
    var linedWidth: CGFloat = 4
    @State private var rotation: Double = 0
    @State private var extraRotation: Double = 0
    @State private var isAnimating: Bool = false
    var body: some View {
        ZStack {
            Circle()
                .stroke(tint.opacity(0.3), style: .init(lineWidth: linedWidth, lineCap: .round, lineJoin: .round))

            Circle()
                .trim(from: 0, to: 0.3)
                .stroke(tint, style: .init(lineWidth: linedWidth, lineCap: .round, lineJoin: .round))
                .rotationEffect(.init(degrees: rotation))
                .rotationEffect(.init(degrees: extraRotation))
        }
        .compositingGroup()
        .onAppear(perform: animate)
    }

    private func animate() {
        guard !isAnimating else { return }
        isAnimating = true

        withAnimation(.linear(duration: 0.7).speed(1.2).repeatForever(autoreverses: false)) {
            rotation += 360
        }

        withAnimation(.linear(duration: 1).speed(1.2).delay(1).repeatForever(autoreverses: false)) {
            extraRotation += 360
        }
    }
}

#Preview {
    AnimatedSpinnerView(tint: .green, linedWidth: 4)
        .frame(width: 30, height: 30)
}
