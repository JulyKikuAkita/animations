//
//  HorizontalInfiniteScrollDateView.swift
//  animation
//
//  Created on 7/4/26.
//
//  SwiftUI learning notes — key takeaways in this file:
//
//  1. INFINITE SCROLL WITH A FIXED-SIZE WINDOW. We never hold every week in
//     memory. The `weeks` array stays exactly 3 wide (prev / current / next).
//     As the user scrolls to an edge we prepend/append two fresh weeks and
//     drop two from the far end, then silently jump the scroll offset back to
//     the middle. The user only ever sees the center page, so the seam is
//     invisible and the calendar feels endless in both directions.
//
//  2. `.scrollTargetBehavior(.paging)` + `.containerRelativeFrame(.horizontal)`
//     makes each week snap to a full container-width page. That's what lets us
//     reason about position in whole "page" units (see note 4).
//
//  3. DRIVING SCROLL FROM CODE — `scrollPosition`. `ScrollPosition` is the
//     iOS 17+ programmatic handle on a scroll view. See the deep-dive block by
//     the `.scrollPosition($scrollPosition)` modifier below.
//
//  4. READING SCROLL WITHOUT BINDINGS — `.onScrollGeometryChange`. We compute
//     which week is centered from the live content offset (`offset / width`,
//     rounded) instead of plumbing state up from children.
//
//  5. HIDING THE RESHUFFLE — `Transaction`. When we mutate `weeks` and re-center
//     the offset, doing it naively causes a visible flicker. A `Transaction`
//     lets us re-center *without* animation and while preserving fling velocity,
//     so the swap is seamless. See the deep-dive block at the `withTransaction`
//     call site below.
//
//  Key APIs
//  ────────
//  • `ScrollPosition` + `.scrollPosition($binding)` — programmatic scroll.
//  • `scrollPosition.scrollTo(id:)` / `.scrollTo(x:)` — jump to a view or offset.
//  • `.onScrollGeometryChange(for:_:action:)` — observe contentOffset/insets.
//  • `.scrollTargetBehavior(.paging)` — snap each page to container width.
//  • `Transaction` + `withTransaction` — override animation/behavior for the
//    state changes made inside the closure.
//
//  How to apply
//  ────────────
//  Reach for this pattern whenever you need a bidirectional infinite pager
//  (calendars, timelines, image reels) but don't want an unbounded data source.
//  The reusable nugget is: keep a small sliding window, and after re-windowing
//  the data, re-anchor the scroll offset inside a non-animated `Transaction`
//  so the recycle is invisible.
//

import SwiftUI

struct InfiniteHScrollDemoView: View {
    @State private var selection: Date = .now
    private let calendar = Calendar.current
    var body: some View {
        VStack {
            HorizontalCalendar(date: $selection) { day in
                let isSelected = calendar.isDate(selection, inSameDayAs: day.date)

                VStack(spacing: 6) {
                    Text(day.weekdaySymbol)
                        .font(.caption)
                        .foregroundStyle(.gray)

                    Text("\(day.value)")
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundStyle(isSelected ? .white : (day.noteFromThisMonth ? .gray : .primary))
                        .frame(width: 38, height: 38)
                        .background {
                            if isSelected {
                                Circle()
                                    .fill(.blue)
                            }
                        }
                        .contentShape(.rect)
                        .onTapGesture {
                            withAnimation(.snappy) {
                                selection = day.date
                            }
                        }
                }
            }
        }
        .padding()
    }
}

struct HorizontalCalendar<Content: View>: View {
    var updatesDateOnScroll: Bool = true
    @Binding var date: Date
    var content: (Day) -> Content

    init(
        updatesDateOnScroll: Bool = true,
        date: Binding<Date>,
        @ContentBuilder content: @escaping (Day) -> Content
    ) {
        self.updatesDateOnScroll = updatesDateOnScroll
        _date = date
        self.content = content

        /// init view with prev, current, next week content
        let weeks: [Week] = (-1 ... 1).compactMap {
            Week.load(from: date.wrappedValue, value: $0)
        }
        self.weeks = weeks
    }

    /// View Properties
    @State private var weeks: [Week]
    /// `ScrollPosition` is the two-way channel between our code and the scroll
    /// view. Bind it with `.scrollPosition($scrollPosition)`, then call
    /// `scrollPosition.scrollTo(id:)` / `.scrollTo(x:)` to *drive* the scroll,
    /// or read it back to know where the scroll currently is.
    @State private var scrollPosition: ScrollPosition = .init()
    @State private var containerSize: CGSize = .zero
    @State private var isLocked: Bool = false
    @State private var lockedID: String?
    /// view starts at center
    @State private var weekIndex: Int = 1

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 0) {
                ForEach(weeks) { week in
                    HStack(spacing: 0) {
                        ForEach(week.days) { day in
                            content(day)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    /// Force each week to be exactly one container (screen) wide,
                    /// so paging snaps cleanly and offsets fall on whole-page
                    /// multiples — the basis for the threshold math below.
                    .containerRelativeFrame(.horizontal)
                    /// THE MASK/PIN THAT MAKES THE RESHUFFLE INVISIBLE.
                    /// `.visualEffect` mutates appearance without triggering
                    /// layout, using the live scroll geometry (`proxy`). While
                    /// `isLocked` (the brief moment we recycle the `weeks`
                    /// window):
                    ///   • opacity — show ONLY the locked edge week, hide the
                    ///     others, so the insert/remove churn on the array can't
                    ///     be seen.
                    ///   • offset `-minX` — cancel out the scroll offset for the
                    ///     locked week, freezing it on screen even as the content
                    ///     underneath is rebuilt and re-centered.
                    /// When not locked, both are no-ops (opacity 1, offset 0) and
                    /// the calendar scrolls normally.
                    /// `[isLocked, lockedID]` is captured by value so the closure
                    /// re-runs when either flips.
                    .visualEffect { [isLocked, lockedID] content, proxy in
                        let minX = proxy.frame(in: .scrollView(axis: .horizontal)).minX

                        return content
                            .opacity(isLocked ? (lockedID == week.id ? 1 : 0) : 1)
                            .offset(x: isLocked ? -minX : 0)
                    }
                }
            }
        }
        .onAppear {
            /// Start on the middle week (index 1). Because the window is
            /// prev/current/next, centering here leaves room to scroll one full
            /// page in either direction before we need to re-window the data.
            if weeks.indices.contains(1) {
                scrollPosition.scrollTo(id: weeks[1].id)
            }
        }
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.paging)
        /// HOW `scrollPosition` ACHIEVES THE INFINITE EFFECT
        /// ─────────────────────────────────────────────────
        /// Binding the position here gives us a programmatic handle on the
        /// scroll offset. The infinite illusion is a two-step trick:
        ///   1. The user scrolls to an edge page → we swap the data window
        ///      (see `.onScrollGeometryChange` below) so fresh weeks exist.
        ///   2. We then call `scrollPosition.scrollTo(x:)` to yank the offset
        ///      back toward the center. Since the just-inserted weeks make the
        ///      content that lay under the finger identical before and after,
        ///      the jump is invisible — the calendar appears to scroll forever.
        /// Note: a bound `ScrollPosition` only reflects changes that originate
        /// from content/programmatic updates, not every gesture frame — for
        /// per-frame offset we use `.onScrollGeometryChange`.
        .scrollPosition($scrollPosition)
        /// Anchor the *initial* content offset to center so we open on the
        /// middle week rather than the leading edge.
        .defaultScrollAnchor(.center, for: .initialOffset)
        /// Track the container (screen) width; every threshold below is
        /// expressed in multiples of it.
        .onGeometryChange(for: CGSize.self) {
            $0.size
        } action: { newValue in
            containerSize = newValue
        }
        /// Observe the live horizontal offset every frame. `contentOffset.x +
        /// contentInsets.leading` normalizes so 0 == the leading edge of the
        /// first week regardless of safe-area insets.
        .onScrollGeometryChange(for: CGFloat.self) {
            $0.contentOffset.x + $0.contentInsets.leading
        } action: { _, newValue in
            guard containerSize.width != .zero else { return }
            /// Which of the 3 pages is centered: offset / pageWidth, rounded.
            weekIndex = Int((newValue / containerSize.width).rounded())

            /// Edge detection, in page units. The window is 3 wide, so valid
            /// offsets span 0 … 2×width. Crossing below 0 means the user pulled
            /// past the first week (need earlier weeks); crossing above 2×width
            /// means past the last (need later weeks).
            let addPreviousWeeks = newValue < 0
            let addNextWeeks = newValue > (containerSize.width * 2)

            if addPreviousWeeks || addNextWeeks, !isLocked {
                guard let firstWeekDate = weeks.first?.days.first?.date else { return }
                guard let lastWeekDate = weeks.last?.days.first?.date else { return }

                let previousTwoWeeks: [Week] = [
                    .load(from: firstWeekDate, value: -2),
                    .load(from: firstWeekDate, value: -1),
                ]

                let nextTwoWeeks: [Week] = [
                    .load(from: lastWeekDate, value: 1),
                    .load(from: lastWeekDate, value: 2),
                ]

                if addPreviousWeeks {
                    lockedID = weeks.first?.id
                } else {
                    lockedID = weeks.last?.id
                }
                isLocked = true

                /// Slide the window: add 2 on the entered side, drop 2 from the
                /// far side, so the array stays exactly 3 wide. Adding 2 (not 1)
                /// is what lets the re-center below jump by a constant 2×width
                /// and always land back on the middle page.
                if addPreviousWeeks {
                    weeks.insert(contentsOf: previousTwoWeeks, at: 0)
                    weeks.removeLast(2)
                } else {
                    weeks.append(contentsOf: nextTwoWeeks)
                    weeks.removeFirst(2)
                }
            } else {
                /// ensure update only happens after view content update to avoid flicker when scroll
                if isLocked {
                    /// WHAT IS A `Transaction`?
                    /// ────────────────────────
                    /// A `Transaction` is the context SwiftUI attaches to every
                    /// state change — it carries *how* the resulting UI update
                    /// should be performed (which animation, whether animations
                    /// are disabled, and scroll-specific flags). `withAnimation`
                    /// is really just sugar for "run this change in a transaction
                    /// whose `.animation` is set." Here we build a transaction by
                    /// hand to customize scroll behavior instead of animation.
                    ///
                    /// Why we need it here:
                    /// We're programmatically re-centering the scroll offset the
                    /// instant after we recycled the `weeks` array. Two problems
                    /// to avoid —
                    ///   • A default `scrollTo` might animate the jump, which
                    ///     would show the content sliding and expose the seam.
                    ///   • The user is often mid-fling; a naive jump kills their
                    ///     momentum and the scroll stops dead.
                    ///
                    /// `scrollPositionUpdatePreservesVelocity = true` tells the
                    /// scroll view to carry the existing fling velocity through
                    /// the programmatic re-anchor, so the finger-flick continues
                    /// smoothly across the recycle boundary. Wrapping the
                    /// `scrollTo` in `withTransaction(_:)` applies this flag only
                    /// to the state changes made inside the closure.
                    var transaction = Transaction()
                    transaction.scrollPositionUpdatePreservesVelocity = true
                    withTransaction(transaction) {
                        if addPreviousWeeks {
                            scrollPosition.scrollTo(x: containerSize.width * 2)
                        } else {
                            scrollPosition.scrollTo(x: -containerSize.width * 2)
                        }
                    }
                }

                /// DEFER THE UNLOCK BY ONE RUN-LOOP TICK.
                /// The `scrollTo` above only *schedules* the re-center; the
                /// scroll view commits the new offset on a later pass. If we
                /// unlocked synchronously here, the `.visualEffect` would drop
                /// the `-minX` pin and re-show every week while the offset is
                /// still settling → a one-frame jump/flicker. `async` pushes the
                /// unlock to the next tick, so the pin is removed only after the
                /// offset already matches where the pinned week sat — seamless.
                /// (This is sequencing, not threading — we're already on main;
                /// `Task { @MainActor in … }` would be the modern equivalent.)
                DispatchQueue.main.async {
                    isLocked = false
                    lockedID = nil
                }
            }
        }
        /// Keep the bound `date` in sync as the centered week changes. We keep
        /// the same weekday the user was on: `.weekday` is 1-based (Sun = 1), so
        /// `- 1` converts it to the 0-based index into that week's `days`.
        .onChange(of: weekIndex) { _, newValue in
            if updatesDateOnScroll, weeks.indices.contains(newValue) {
                let symbolIndex = Calendar.current.component(.weekday, from: date) - 1
                date = weeks[newValue].days[symbolIndex].date
            }
        }
    }
}

#Preview {
    InfiniteHScrollDemoView()
}
