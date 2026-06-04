//
//  SliderWorkaroundScrollView.swift
//  animation
//
//  Learning point
//  ──────────────
//  Workshop file documenting an iOS 18 gesture regression: a
//  custom horizontal slider inside a vertical `ScrollView` would
//  STEAL all touches on iOS 18 (works fine on iOS 17), making the
//  scroll view non-pullable when the slider is on screen. Three
//  variants in the file demonstrate the problem and two fixes:
//
//    • `VolumeSliderWithIssue` — naive baseline. Default
//      `DragGesture()` wins exclusively → scroll dies.
//    • `VolumeSlider` (Fix 1) — bump `minimumDistance: 30`. SwiftUI
//      only routes touches to the gesture once the finger has moved
//      30pt; vertical pulls under 30pt go to the scroll view.
//      Side effect: brief "dead zone" before slider responds.
//    • `VolumeSliderWithSimultaneousGesture` (Fix 2, iOS 18 only) —
//      use `.simultaneousGesture` AND inspect `value.velocity` to
//      decide who owns the drag. If `velocity.height == 0` the user
//      is moving horizontally → set `isScrollDisabled = true` so the
//      parent scroll view stops competing. On end, re-enable scroll.
//
//  Why iOS 18 broke it
//  ───────────────────
//  iOS 18 reworked SwiftUI's gesture priority for `ScrollView`. With
//  default-priority `.gesture`, the slider's drag now consumes both
//  axes; the scroll view no longer gets touches it didn't already own.
//  `.simultaneousGesture` + velocity inspection is Apple's recommended
//  pattern from WWDC 24's "What's new in SwiftUI" (gesture composition
//  section).
//
//  How `velocity` decides the winner
//  ─────────────────────────────────
//  `DragGesture.Value.velocity` (iOS 17+) gives instantaneous pixels-
//  per-second on each axis at the moment of the change event. We
//  capture it on the FIRST `onChanged` and never overwrite — the
//  initial direction usually wins, even if the user wobbles. If
//  `velocity.height == 0` (purely horizontal start) the slider claims
//  the gesture; otherwise (any vertical component) it lets scroll
//  proceed normally.
//
//  Why `minimumDistance: 1` (not 0) in Fix 2
//  ─────────────────────────────────────────
//  `DragGesture(minimumDistance: 0)` fires at TOUCH-DOWN, not on
//  movement — at touch-down `velocity` is `.zero`, so we'd
//  short-circuit and never read a meaningful direction. Bumping to
//  `1` ensures the first event has at least one frame of motion
//  measured.
//
//  Key APIs
//  ────────
//  • `DragGesture(minimumDistance:)` — slack before recognition.
//  • `.simultaneousGesture` — gesture runs alongside (not instead of)
//    the parent scroll's gesture.
//  • `DragGesture.Value.velocity` — directional intent at the
//    current event.
//  • `.scrollDisabled(_:)` — programmatically gate scrolling per
//    state.
//
//  How to apply
//  ────────────
//  Use Fix 2 anytime a horizontal-drag custom control sits inside a
//  vertical scroll view (sliders, sliders-in-sliders, swipe-to-dismiss
//  cells). The "first-event velocity wins" pattern is the load-bearing
//  idea — much more reliable than trying to compute slope mid-drag.
//

import SwiftUI

struct SliderWorkaroundScrollDemoView: View {
    @State private var isScrollDisabled: Bool = false
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Volume")
                        .font(.caption2)
                        .foregroundStyle(.gray)

                    Text(isScrollDisabled ? "Scroll Disabled" : "Scroll Enabled")

                    VolumeSliderWithSimultaneousGesture(isScrollDisabled: $isScrollDisabled)
                }
                .padding()
            }
            .scrollDisabled(isScrollDisabled)
            .navigationTitle("Gesture - iOS 18")
        }
    }
}

/// fix 1. use DragGesture(minimumDistance: 30)
struct VolumeSlider: View {
    @Binding var isScrollDisabled: Bool
    @State private var progress: CGFloat = 0
    @State private var lastProgress: CGFloat = 0

    var body: some View {
        GeometryReader {
            let size = $0.size

            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(.ultraThinMaterial)

                Rectangle()
                    .fill(.black)
                    .frame(width: progress * size.width)
            }
            .clipShape(.rect(cornerRadius: 10))
            .gesture(
                DragGesture(minimumDistance: 30) /// fix 1: increase translation value from default 10 to 30
                    .onChanged { value in
                        let progress = (value.translation.width / size.width) + lastProgress
                        self.progress = max(min(progress, 1), 0)
                    }.onEnded { _ in
                        lastProgress = progress
                    }
            )
        }
        .frame(height: 40)
    }
}

/// iOS 18 only
/// fix 2: use simultaneousGesture
struct VolumeSliderWithSimultaneousGesture: View {
    @Binding var isScrollDisabled: Bool
    @State private var progress: CGFloat = 0
    @State private var lastProgress: CGFloat = 0
    @State private var velocity: CGSize = .zero /// help identity  scroll or slider gesture

    var body: some View {
        GeometryReader {
            let size = $0.size

            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(.ultraThinMaterial)

                Rectangle()
                    .fill(.black)
                    .frame(width: progress * size.width)
            }
            .clipShape(.rect(cornerRadius: 10))
            // Tip: Fix-2 logic flow on iOS 18.
            //   1. First `onChanged`: capture `value.velocity` once.
            //      Don't overwrite — initial direction wins, prevents
            //      mid-drag flicker between modes.
            //   2. If the captured velocity has any vertical component
            //      (`velocity.height != 0`), abort the slider update —
            //      the user is scrolling, let it pass through.
            //   3. If purely horizontal, claim the gesture by setting
            //      `isScrollDisabled = true` so the parent scroll
            //      cooperates with us instead of fighting.
            //   4. `onEnded`: reset velocity capture and re-enable
            //      scrolling so the next gesture can re-decide.
            .simultaneousGesture(
                customGesture
                    .onChanged { value in
                        if #available(iOS 18, *) {
                            if velocity == .zero {
                                velocity = value.velocity
                            }

                            guard velocity.height == 0 else { return }
                            isScrollDisabled = true
                        }
                        let progress = (value.translation.width / size.width) + lastProgress
                        self.progress = max(min(progress, 1), 0)
                    }.onEnded { _ in
                        lastProgress = progress
                        if #available(iOS 18, *) {
                            velocity = .zero
                            isScrollDisabled = false
                        }
                    }
            )
        }
        .frame(height: 40)
    }

    /// Tip: `minimumDistance: 1` is intentional, not arbitrary.
    /// `0` fires at touch-DOWN where `velocity == .zero`, defeating
    /// the velocity-based direction check. `1` ensures the first
    /// event already has a measurable direction. iOS 17 falls back
    /// to default `DragGesture()` because the regression doesn't
    /// affect that version.
    var customGesture: DragGesture {
        if #available(iOS 18, *) {
            DragGesture(minimumDistance: 1)
        } else {
            DragGesture()
        }
    }
}

/// only in iOS 18 (not seen in iOS 17)
/// Volume slider does not allow scroll interaction (not able to pull up/down)
struct VolumeSliderWithIssue: View {
    @Binding var isScrollDisabled: Bool
    @State private var progress: CGFloat = 0
    @State private var lastProgress: CGFloat = 0

    var body: some View {
        GeometryReader {
            let size = $0.size

            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(.ultraThinMaterial)

                Rectangle()
                    .fill(.black)
                    .frame(width: progress * size.width)
            }
            .clipShape(.rect(cornerRadius: 10))
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let progress = (value.translation.width / size.width) + lastProgress
                        self.progress = max(min(progress, 1), 0)
                    }.onEnded { _ in
                        lastProgress = progress
                    }
            )
        }
        .frame(height: 40)
    }
}

#Preview {
    SliderWorkaroundScrollDemoView()
}
