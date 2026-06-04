//
//  AnimatedScrollableSliderIOS26DemoView.swift
//  animation
//
//  Created on 12/22/25.
//
//  Learning point
//  ──────────────
//  Camera-app / wheel-picker style horizontal tick slider that
//  animates the *intermediate* ticks as the user flings through
//  values, not just the start and end. Each tick smoothly grows /
//  shrinks / changes colour as the wheel passes through it — feels
//  far more analog than the default snap-to-value behaviour.
//
//  Why we can't drive this from `scrollPosition` alone
//  ───────────────────────────────────────────────────
//  Reading the binding's `scrollPosition` directly during a fast
//  scroll causes it to *jump* between values (SwiftUI debounces
//  intermediate states). Each in-between tick never sees an "I'm
//  active" flag, so they don't animate.
//
//  The fix in this file is a `animationRange: ClosedRange<Int>`
//  computed from BOTH the previous and current scroll index. As the
//  user scrolls from index 30 → 45, every tick whose index is in
//  `30...45` gets `isInside = true`, triggering its grow/highlight
//  animation. When the scroll lands, the range collapses to
//  `n...n` so only the final tick stays highlighted.
//
//  Three signals that work together
//  ────────────────────────────────
//    1. **`onScrollGeometryChange`** — fires every frame during
//       interactive scroll. We compute `index = round(offset / width)`
//       and update `animationRange` to the (prev, current) span.
//    2. **`onScrollPhaseChange`** — fires on `.idle / .interacting /
//       .decelerating`. On idle, we collapse `animationRange` to a
//       single tick AND nudge `scrollPosition` if `viewAligned` left
//       the active tick slightly off-centre (a known iOS edge case).
//    3. **`scrollTargetBehavior(.viewAligned(.alwaysByOne))`** —
//       snap to the nearest single tick after a fling, never two.
//
//  Why the `task { }` initial-setup gate
//  ─────────────────────────────────────
//  `allowsHitTesting(completeInitialSetup)` blocks user gestures
//  until the first programmatic scroll has settled. Without it,
//  tapping during the initial layout pass races with `scrollPosition`
//  resolution and jumps to the wrong tick.
//
//  Key APIs
//  ────────
//  • `ScrollPhase` + `onScrollPhaseChange` (iOS 17+) — interactive
//    vs decelerating vs idle.
//  • `onScrollGeometryChange(for:of:action:)` — live offset reads.
//  • `scrollTargetBehavior(.viewAligned(limitBehavior: .alwaysByOne))`
//    — single-tick snap.
//  • `safeAreaPadding(.horizontal, ...)` — centres the first/last
//    ticks so they can be selected (otherwise they sit at the edges).
//  • `.animation(isInside ? .none : config.animation, value: isInside)` —
//    DON'T animate the entry into the range (we want the value to
//    update instantly), only animate the exit (the elastic shrink).
//
//  How to apply
//  ────────────
//  Reach for this whenever a scroll-driven value picker needs to feel
//  fluid: camera EV, brightness, exposure, slider with audible "tick"
//  feedback. The (prev, current) range pattern generalises to any
//  scroll-derived UI that should animate items as the cursor SWEEPS
//  across them.
//

import SwiftUI

struct AnimatedScrollableSliderIOS26DemoView: View {
    @State private var selection: Int = 0

    var body: some View {
        NavigationStack {
            VStack {
                TickPicker(count: 100, config: config, selection: $selection)

                Text("\(selection)")
                    .monospaced()
                    .fontWeight(.medium)

                Button("Update tick to center") {
                    selection = 50
                }
            }
            .navigationTitle("Tick Picker")
        }
    }

    var config: TickConfig {
        .init(tickWidth: 2,
              alignment: .center)
    }
}

struct TickPicker: View {
    var count: Int
    var config: TickConfig = .init()
    @Binding var selection: Int

    /// View Properties
    @State private var scrollIndex: Int = 0
    @State private var scrollPosition: Int?
    @State private var scrollPhase: ScrollPhase = .idle
    @State private var animationRange: ClosedRange<Int> = 0 ... 0
    @State private var completeInitialSetup: Bool = false
    var body: some View {
        GeometryReader {
            let size = $0.size

            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(0 ... count, id: \.self) { index in
                        tickView(index)
                    }
                }
                .frame(height: config.tickHeight)
                .frame(maxHeight: .infinity)
                .contentShape(.rect)
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned(limitBehavior: .alwaysByOne))
            .scrollPosition(id: $scrollPosition, anchor: .center)
            /// centering tick start/end point
            .safeAreaPadding(.horizontal, (size.width - width) / 2)
            // Tip: live geometry → range mapping.
            // `index = round(offsetX / width)` is the tick currently
            // under the centre. We extend `animationRange` from the
            // PREVIOUS tick to the new one so every tick the cursor
            // *passes through* gets `isInside = true` for that frame.
            // Skipped while idle so we don't constantly rewrite the
            // range to a single tick.
            .onScrollGeometryChange(for: CGFloat.self) {
                $0.contentOffset.x + $0.contentInsets.leading
            } action: { _, newValue in
                guard scrollPhase != .idle else { return }
                let index = max(min(Int((newValue / width).rounded()), count), 0)
                let previousScrollIndex = scrollIndex
                scrollIndex = index

                let isGreater = scrollIndex > previousScrollIndex
                let leadingBound = isGreater ? previousScrollIndex : scrollIndex
                let trailingBound = !isGreater ? previousScrollIndex : scrollIndex

                animationRange = leadingBound ... trailingBound
            }
            // Tip: phase changes do two cleanup jobs.
            //   1. Collapse `animationRange` to a single tick — without
            //      this, fast successive scrolls would leave a stale
            //      span of "active" ticks that never deactivate.
            //   2. On `.idle`, force `scrollPosition` to the snapped
            //      tick. `viewAligned` occasionally settles a hairline
            //      off-centre; this nudge centres it perfectly.
            .onScrollPhaseChange { _, newPhase in
                scrollPhase = newPhase
                // avoid animation staggering when rapid update on tick
                animationRange = scrollIndex ... scrollIndex

                /// Fix edge cases when view aligned target will not center the tick
                if newPhase == .idle, scrollPosition != scrollIndex {
                    withAnimation(config.animation) {
                        scrollPosition = scrollIndex
                    }
                }
            }
        }
        .frame(height: config.interactionHeight)
        .task {
            guard !completeInitialSetup else { return }

            /// Setup initial scroll
            updateScrollPosition(selection: selection)

            completeInitialSetup = true
        }
        .allowsHitTesting(completeInitialSetup)
        .onChange(of: scrollIndex) { _, newValue in
            Task {
                selection = newValue
            }
        }
        .onChange(of: selection) { _, newValue in
            guard scrollIndex != newValue else { return }
            updateScrollPosition(selection: newValue)
        }
    }

    @ViewBuilder
    func tickView(_ index: Int) -> some View {
        let height = config.tickHeight
        let isInside = animationRange.contains(index)
        let fillColor = scrollIndex == index ? config.activeTint : config.inactiveTint.opacity(isInside ? 1 : 0.4)
        Rectangle()
            .fill(fillColor)
            .frame(
                width: config.tickWidth,
                height: height * (isInside ? 1 : config.inActiveHeightProgress)
            )
            .frame(width: width, height: height, alignment: config.alignment.value)
            .clipped()
            // Tip: asymmetric animation — the ENTRY into the range is
            // instant (we want the cursor's leading edge to track the
            // finger 1:1), but the EXIT is animated (springy shrink
            // back to the inactive height). Hence the `isInside` check
            // gates whether to apply `.animation` at all.
            .animation(isInside || completeInitialSetup ? .none : config.animation, value: isInside)
    }

    func updateScrollPosition(selection: Int) {
        let safeSelection = max(min(selection, count), 0)
        scrollPosition = safeSelection
        scrollIndex = safeSelection
        animationRange = safeSelection ... safeSelection
    }

    var width: CGFloat {
        config.tickWidth + (config.tickHPadding * 2)
    }
}

struct TickConfig {
    var tickWidth: CGFloat = 3
    var tickHeight: CGFloat = 30
    var tickHPadding: CGFloat = 3
    var inActiveHeightProgress: CGFloat = 0.55
    var interactionHeight: CGFloat = 60
    var activeTint: Color = .yellow
    var inactiveTint: Color = .primary
    var alignment: Alignment = .bottom
    var animation: Animation = .interpolatingSpring(duration: 0.3, bounce: 0, initialVelocity: 0)

    enum Alignment: String, CaseIterable {
        case top = "TOP"
        case bottom = "Bottom"
        case center = "Center"

        var value: SwiftUI.Alignment {
            switch self {
            case .top: .top
            case .bottom: .bottom
            case .center: .center
            }
        }
    }
}

#Preview {
    AnimatedScrollableSliderIOS26DemoView()
}
