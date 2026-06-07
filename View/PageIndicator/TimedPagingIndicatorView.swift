//
//  TimedPagingIndicatorView.swift
//  animation
//
//  Created on 6/7/26.
//
//  How to use TimedPagingIndicatorView
//  -----------------------------------
//  A capsule-style page indicator that auto-advances `selection` after
//  `duration` seconds, and pauses while the user is interacting (e.g.
//  mid-scroll). Pair it with a horizontal paging ScrollView whose page
//  index is bound to the same `selection`.
//
//  Required wiring:
//    1. Two @State values in the parent: `activeIndex: Int` and
//       `isPaused: Bool`.
//    2. Bind the ScrollView's page index via `.scrollPosition(id:)` to
//       `activeIndex` so programmatic advances scroll the content.
//    3. Drive `isPaused` from `.onScrollPhaseChange` — set it true while
//       the phase is anything other than `.idle` / `.animating` so the
//       timer halts during a drag.
//    4. Pass `count`, `duration`, `isPaused`, and `$activeIndex` to
//       TimedPagingIndicatorView. Optional: override `activeTint` /
//       `inActiveTint`.
//
//  Behavior:
//    - The active capsule expands and fills left-to-right over `duration`.
//    - When progress hits 1, `selection` advances (wraps at the end).
//    - Changing `selection` externally (user scroll) resets the timer.
//
//  See AutoAdvancingPageIndicatorDemo below for a full example.

import SwiftUI

struct AutoAdvancingPageIndicatorDemo: View {
    @State private var isPaused: Bool = false
    @State private var activeIndex: Int = 0
    var body: some View {
        VStack {
            ScrollView(.horizontal) {
                LazyHStack(spacing: 10) {
                    ForEach(dummyBeamColors.indices, id: \.self) { index in
                        let color = dummyBeamColors[index]
                        DummyRectangles(color: color, count: 1, height: 180)
                            .containerRelativeFrame(.horizontal)
                    }
                }
                .scrollTargetLayout()
            }
            .safeAreaPadding(.horizontal, 10)
            .scrollIndicators(.hidden)
            .scrollPosition(id: .init(get: {
                activeIndex
            }, set: { newIndex in
                guard let newIndex else { return }
                activeIndex = newIndex
            }), anchor: .center)
            .scrollTargetBehavior(.viewAligned(limitBehavior: .alwaysByOne))
            .frame(height: 220)
            .onScrollPhaseChange { _, newPhase in
                isPaused = newPhase != .idle && newPhase != .animating
            }
            .animation(.easeInOut(duration: 0.25), value: activeIndex)

            TimedPagingIndicatorView(
                count: 5,
                duration: 2,
                isPaused: isPaused,
                selection: $activeIndex
            )
        }
        .padding()
    }
}

struct TimedPagingIndicatorView: View {
    var count: Int // total number of pages
    var duration: CGFloat // seconds before auto-advance
    var isPaused: Bool // halts the fill while the user is interacting
    var activeTint: Color = .primary
    var inActiveTint: Color = .gray
    @Binding var selection: Int

    /// View Properties
    // Anchor for elapsed-time math; reset on selection change or pause toggle.
    @State private var startDate: Date = .now
    // Optional override so the first frame after appear uses the parent's pause state
    // without waiting for the binding to propagate through TimelineView.
    @State private var isTimelinePaused: Bool?
    var body: some View {
        // TimelineView ticks each frame so we can derive `progress` from wall-clock
        // time. Pausing the timeline is what freezes the fill animation.
        TimelineView(.animation(paused: isTimelinePaused ?? isPaused)) { ctx in
            let diff = startDate.distance(to: ctx.date)
            let progress = (diff / duration).clamped(to: 0 ... 1)
            // Crosses from 0 → 1 exactly once per cycle; used as the advance trigger.
            let progressIndex = Int(progress)

            HStack(spacing: 5) {
                ForEach(0 ..< count, id: \.self) { index in
                    let isActive = selection == index

                    Rectangle()
                        .fill(inActiveTint)
                        .overlay {
                            if isActive {
                                // The active capsule fills left-to-right by scaling
                                // an overlay rectangle. When paused, snap to full
                                // width so it reads as "selected, not progressing".
                                Rectangle()
                                    .fill(activeTint)
                                    .scaleEffect(x: isPaused ? 1 : progress, anchor: .leading)
                            }
                        }
                        // Active capsule expands to 20pt while progressing, collapses
                        // back to a 5pt dot when paused or inactive.
                        .frame(width: isActive ? (isPaused ? 5 : 20) : 5,
                               height: 5)
                        .clipShape(.capsule)
                }
            }
            .frame(maxHeight: .infinity)
            .onChange(of: progressIndex) { _, newValue in
                // Fires once per cycle when progress saturates at 1.
                if newValue == 1 {
                    advanceIndex()
                }
            }
        }
        .frame(height: 10)
        .onChange(of: selection) { _, _ in
            // Restart the timer whenever the page changes — covers both auto-advance
            // and external changes (e.g. user-driven scroll).
            startDate = .now
        }
        .onChange(of: isPaused) { _, newValue in
            // Resuming after a pause should restart the cycle, not continue from
            // where the user grabbed it.
            startDate = .now
            isTimelinePaused = newValue
        }
        .onAppear {
            isTimelinePaused = isPaused
        }
        .animation(.iSpring(), value: selection)
        .animation(.iSpring(), value: isPaused)
    }

    // Advances to the next page and wraps to 0 at the end.
    func advanceIndex() {
        if selection == (count - 1) {
            selection = 0
        } else {
            let nextIndex = min(selection + 1, count - 1)
            selection = nextIndex
        }
    }
}

#Preview {
    AutoAdvancingPageIndicatorDemo()
}
