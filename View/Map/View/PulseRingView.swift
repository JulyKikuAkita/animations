//
//  PulseRingView.swift
//  animation
//
//  Created on 11/14/25.
//
//  ⚠️  REUSABLE HELPER, NOT A STANDALONE DEMO. Consumed by
//      [[CustomMapView]] as the pulsing ring around a selected
//      map pin. Designed to be cheap enough to use anywhere.
//
//  Original notes (kept verbatim):
//    • The view only animates when `scenePhase` signals foreground.
//    • Stops animating in background to preserve battery.
//
//  Learning point
//  ──────────────
//  Three concentric circles that scale OUT and fade simultaneously,
//  with each ring offset by 0.2s so the user sees a "wave" of pulses
//  rather than a single throb. Drop in anywhere a UI element should
//  draw attention without occupying the whole screen.
//
//  scenePhase awareness — battery-saving pattern
//  ─────────────────────────────────────────────
//  `repeatForever(autoreverses: false)` animations DON'T stop when
//  the app backgrounds — they keep ticking on the render thread,
//  burning battery on a screen no one is looking at. The fix is
//  the `.onChange(of: phase, initial: true)` handler that flips
//  `showRings = false` on background, removing the animated views
//  from the hierarchy entirely. On foreground, `start()` re-installs
//  them. Worth copying to any "pulse / shimmer / spin forever" view.
//
//  Mechanics:
//    • `@State animate: [Bool]` of three flags, one per ring.
//    • `start()` toggles each flag inside its own
//      `withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: false).delay(index * 0.2))`,
//      staggering them.
//    • `reset()` slams all three back to false on background, which
//      also halts any in-flight animation.
//
//  Key APIs
//  ────────
//  • `@Environment(\.scenePhase)` — read app foreground/background
//    state declaratively.
//  • `.onChange(of:initial:)` — iOS 17+. The `initial: true`
//    variant fires once at view creation so we don't need a
//    separate `.onAppear` for the same logic.
//  • `withAnimation(.easeInOut(...).repeatForever(autoreverses: false).delay(_:))`
//    — chained animation modifiers; `.delay` staggers ring start.
//  • `.scaleEffect(_)` + `.opacity(_)` ramp simultaneously to fake
//    a "ring expanding outward and fading."
//
//  How to apply
//  ────────────
//  Drop next to any pin / icon / FAB that should draw attention.
//  Two parameters: `tint` and `size`. The 3-ring count, 2-second
//  duration, and 0.2-second stagger are tuned for the map-pin use
//  case — increase the count or stretch the duration if you want
//  a slower, gentler pulse.
//
//  See also
//  ────────
//  • CustomMapView.swift — the consumer; pulses around the
//    selected map pin.
//
import SwiftUI

struct PulseRingView: View {
    var tint: Color
    var size: CGFloat
    /// View Properties
    @State private var animate: [Bool] = [false, false, false]
    @State private var showRings: Bool = false
    @Environment(\.scenePhase) private var phase

    var body: some View {
        ZStack {
            if showRings {
                ZStack {
                    ringView(index: 0)
                    ringView(index: 1)
                    ringView(index: 2)
                }
            }
        }
        .onChange(of: phase, initial: true) { _, newValue in
            /// hiding animation view when scene is not active
            showRings = newValue != .background
            if showRings {
                start()
            } else {
                reset()
            }
        }
        .onAppear {
            showRings = true
            start()
        }
        .onDisappear {
            reset()
            showRings = false
        }
        .frame(width: size, height: size)
    }

    /// customize as needed
    func ringView(index: Int) -> some View {
        Circle()
            .fill(tint)
            .opacity(animate[index] ? 0 : 0.4)
            .scaleEffect(animate[index] ? 2 : 0)
    }

    /// stop animation when secene is not active
    private func reset() {
        animate = [false, false, false]
    }

    private func start() {
        for index in 0 ..< animate.count {
            let delay = Double(index) * 0.2
            withAnimation(.easeInOut(duration: 2)
                .repeatForever(autoreverses: false)
                .delay(delay)
            ) {
                animate[index] = true
            }
        }
    }
}

#Preview {
    PulseRingView(tint: .blue, size: 200)
}
