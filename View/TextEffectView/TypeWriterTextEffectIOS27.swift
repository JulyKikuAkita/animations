//
//  TypeWriterTextEffectIOS27.swift
//  animation
//
//  Created on 9/1/26.
//
//  Learning point
//  ──────────────
//  Apple-marketing-style headline: each string types itself in character
//  by character beside a blinking caret, holds, un-types, and the next
//  string takes over — looping forever. One scalar `progress` drives the
//  whole thing; four separate pieces read it.
//
//  Mechanics
//  ─────────
//    1. `TimelineView(.periodic(by: cycle))` is the clock. One tick per
//       string, where `cycle = typingDuration + textWaitDelay +
//       dismissDuration + nextContentDelay`; tick index % `texts.count`
//       selects the string.
//    2. `onChange(of: text)` runs one cycle: animate `progress` 0 → 1
//       (type in), sleep through `textWaitDelay`, animate 1 → 0 (un-type).
//       `nextContentDelay` is the slack that guarantees the cycle finishes
//       before the clock ticks again — that is why nothing sleeps at the end.
//    3. `TypingTextRender` (`TextRenderer`) spreads `progress` over the
//       glyphs: glyph *i* owns the window `i/count ... (i+1)/count`.
//    4. `TypingAnimation` (`CustomAnimation`) is what makes it read as
//       *typing* rather than a smooth fade — it quantises progress into
//       glyph slots and pauses inside each slot (`PauseIntensity`).
//    5. Two `visualEffect`s hold the caret still: the text is pushed right
//       by its own width at progress 0, and the line is pulled left by half
//       its width, so the caret stays put while text grows out of it.
//
//  Key APIs
//  ────────
//  • `TextRenderer` + `@Animatable` — per-glyph drawing with an animatable
//    `progress`; `@AnimatableIgnored` keeps the `Bool` out of the
//    interpolated `animatableData`.
//  • `CustomAnimation` — hand-written timing curve; returning `nil` from
//    `animate(value:time:context:)` signals "finished".
//  • `.periodic(from:by:)` — a single stored origin `Date` is the entire
//    scheduler: it anchors the ticks *and* yields the current index by
//    division, so no counter is ever mutated. See `startDate`.
//  • `keyframeAnimator(repeating:)` — the caret blink, independent of
//    `progress` so it keeps blinking between strings.
//  • `visualEffect` — geometry-driven offsets that never invalidate layout.
//  • `CHHapticEngine` — one transient tap per character typed, one
//    continuous rumble on dismiss.
//
//  How to apply
//  ────────────
//  The split is the reusable idea: a `TimelineView` for *when*, a
//  `CustomAnimation` for *how it is paced*, and a `TextRenderer` for *what
//  each glyph looks like*. Any of the three can be swapped alone.
//
//  See also
//  ────────
//  • HackerTextView.swift — per-character reveal via string mutation
//    instead of a renderer.
//  • FlipClockTextEffectView.swift — the `Animatable` pattern on digits.

import CoreHaptics
import SwiftUI

struct TypeWriterTextEffectDemo: View {
    /// Constant data belongs outside `body`. `body` re-runs on every
    /// invalidation, so an inline literal is rebuilt each pass. That rebuild
    /// does not itself cause a redraw downstream — SwiftUI compares the values
    /// handed to a child, and two equal `[String]` compare equal — it is just
    /// avoidable work. Hoisting also keeps `body` to layout only.
    private let texts = [
        "Welcome to Apple",
        "Discover iPhone",
        "Explore Mac",
        "Experience Airpods",
        "Meet Apple Watch",
    ]

    var body: some View {
        NavigationStack {
            VStack {
                TypeWriterTextEffect(
                    config: .init(
                        typingDuration: 1.5
                    ),
                    texts: texts
                )
            }
            .navigationTitle("TypeWriter Text Effect")
            .toolbarTitleDisplayMode(.inline)
        }
    }
}

struct TypingTextConfig {
    var font: Font = .system(size: 25, weight: .bold)
    var typingIndicatorSize: CGSize = .init(width: 20, height: 2.5)

    var dismissDuration: Double = 0.5
    var dismissPauseIntensity: PauseIntensity = .small

    var typingDuration: Double = 1
    var typingPauseIntensity: PauseIntensity = .small

    var textWaitDelay: Double = 1.3
    var nextContentDelay: Double = 0.4

    var enableTextFading: Bool = true

    /// Fraction of each character's time slot spent waiting before that
    /// character animates. `.small` barely hesitates; `.full` never
    /// interpolates, so characters snap in one at a time. See `TypingAnimation`.
    enum PauseIntensity: CGFloat {
        case small = 0.15
        case medium = 0.5
        case large = 0.85
        case full = 1.0
    }
}

#Preview {
    TypeWriterTextEffectDemo()
}

struct TypeWriterTextEffect: View {
    var config: TypingTextConfig = .init()
    var texts: [String]
    /// View Properties
    ///
    /// One stored `Date` replaces a scheduling counter, and carries three jobs:
    ///   • Phase anchor for `.periodic(from:by:)` — `by:` says how *often*,
    ///     `from:` says *when*. It has to be stored: `.periodic(from: .now, …)`
    ///     written inline would re-read the clock on every `body` pass, sliding
    ///     the anchor forward so ticks never land where the last pass predicted.
    ///   • Source of the current index — `(ctx.date - startDate) / duration` is
    ///     how many cycles have elapsed, so the visible string is a pure
    ///     function of time. No `currentIndex` state to keep in sync with the
    ///     animation, and no drift to accumulate the way a repeating `Timer`
    ///     that increments a counter would.
    ///   • "Has the clock started?" gate — `nil` selects the caret-only
    ///     placeholder. Hence `Date?` rather than `.now` at declaration: `@State`
    ///     initial values are computed when the view value is created, which can
    ///     be long before it appears; assigning inside `.task` pins tick 0 to the
    ///     moment it is actually on screen.
    @State private var startDate: Date?
    @State private var progress: CGFloat = .zero
    /// `@State` so the engine survives re-inits of this `View` struct; a plain
    /// stored property would hand back a fresh, unprepared engine on every update.
    @State private var hapticsManager = HapticsManager()
    @Environment(\.scenePhase) private var scenePhase
    var body: some View {
        ZStack {
            if let startDate {
                let duration = config.typingDuration + config.textWaitDelay + config.dismissDuration + config.nextContentDelay
                /// One tick per string: the timeline only sequences, `animateText`
                /// below animates. `.rounded()` absorbs float drift so the tick
                /// lands on a whole index instead of `n - epsilon`.
                TimelineView(.periodic(from: startDate, by: duration)) { ctx in
                    let index = Int((startDate.distance(to: ctx.date) / duration).rounded()) % texts.count
                    let text = texts[index]

                    HStack(alignment: .bottom, spacing: 0) {
                        Text(text)
                            .font(config.font)
                            .textRenderer(
                                TypingTextRender(
                                    fadeEffect: config.enableTextFading,
                                    progress: progress
                                )
                            )
                            /// Text starts fully off to the right of the caret and
                            /// slides back into place as it types, so glyphs appear
                            /// to emerge from the caret rather than beside it.
                            .visualEffect { [progress] content, proxy in
                                let offset = proxy.size.width
                                return content
                                    .offset(x: offset * (1 - progress))
                            }
                        TypingIndicator(size: config.typingIndicatorSize)
                    }
                    /// Counter-shift by half the line so the caret — not the line's
                    /// midpoint — sits centred while the text is still empty.
                    .visualEffect { [config, progress] content, proxy in
                        let offset = (proxy.size.width - config.typingIndicatorSize.width) / 2
                        return content
                            .offset(x: -offset * (1 - progress))
                    }
                    /// `initial: true` runs the first cycle immediately; without it
                    /// the opening string would wait a full tick before typing.
                    .onChange(of: text, initial: true) { _, newValue in
                        animateText(for: newValue)
                    }
                }
            } else {
                /// Placeholder content
                HStack(alignment: .bottom, spacing: 0) {
                    Text(" ")
                        .font(config.font)
                        .frame(width: 0)
                    TypingIndicator(size: config.typingIndicatorSize)
                }
            }
        }
        .lineLimit(1)
        .task {
            /// The guard matters because starting the clock is not idempotent: a
            /// re-entrant `.task` would re-anchor it and restart the sequence.
            guard startDate == nil else { return }
            try? await Task.sleep(for: .seconds(0.7))
            startDate = .now
        }
        .onChange(of: scenePhase, initial: true) { _, newValue in
            if newValue == .active {
                hapticsManager.prepareEngine()
            } else {
                Task {
                    await hapticsManager.stopEngine()
                }
            }
        }
    }

    private func animateText(for text: String) {
        Task {
            playHaptics(text: text, forDismiss: false)
            withAnimation(
                .typingAnimation(
                    text: text,
                    pause: config.typingPauseIntensity,
                    duration: config.typingDuration
                )
            ) {
                progress = 1
            }

            try? await Task.sleep(for: .seconds(config.typingDuration + config.textWaitDelay))

            playHaptics(text: text, forDismiss: true)
            withAnimation(.typingAnimation(
                text: text,
                pause: config.dismissPauseIntensity,
                duration: config.dismissDuration
            )) {
                progress = 0
            }
            // do not add delay here, already include in timeline duration
        }
    }

    private func playHaptics(text: String, forDismiss: Bool) {
        guard scenePhase == .active else { return }
        do {
            let duration = forDismiss ? config.dismissDuration : config.typingDuration
            try hapticsManager.playHaptics(text: text, duration: duration, forDismiss: forDismiss)
        } catch {
            print(error.localizedDescription)
        }
    }
}

private struct TypingIndicator: View {
    var size: CGSize
    var duration: CGFloat = 0.5
    var delay: CGFloat = 0.1
    var body: some View {
        Rectangle()
            .frame(width: size.width, height: size.height)
            .keyframeAnimator(initialValue: CGFloat.zero, repeating: true) { content, opacity in
                content
                    .opacity(opacity)
            } keyframes: { _ in
                /// A blinking caret over a `duration + delay` track: snap to
                /// invisible, fade in over half `duration`, hold (a `LinearKeyframe`
                /// to the value it already has is a hold), then fade out over the
                /// other half. The track starts and ends at 0, so `repeating: true`
                /// loops without a visible seam.
                MoveKeyframe(0)
                LinearKeyframe(1, duration: duration / 2)
                LinearKeyframe(1, duration: delay)
                LinearKeyframe(0, duration: duration / 2)
            }
    }
}

@Animatable
private struct TypingTextRender: TextRenderer {
    @AnimatableIgnored var fadeEffect: Bool
    var progress: CGFloat
    func draw(layout: Text.Layout, in ctx: inout GraphicsContext) {
        /// `Text.Layout` nests lines → runs → glyph slices, so flattening twice
        /// gives one drawable slice per glyph in reading order.
        let slices = layout.flatMap(\.self).flatMap(\.self)
        for (index, slice) in slices.enumerated() {
            var copy = ctx
            /// Give each glyph its own `1 / count` window of the shared progress:
            /// glyph `index` goes 0 → 1 while progress crosses that window, and
            /// clamping keeps glyphs outside it fully hidden or fully drawn.
            let rawProgress = progress * CGFloat(slices.count) - CGFloat(index)
            let sliceProgress = rawProgress.clamped(to: 0 ... 1)

            if fadeEffect {
                copy.opacity = sliceProgress
            } else {
                /// Rounding collapses the fade into a hard cut, so glyphs pop in.
                copy.opacity = sliceProgress.rounded()
            }

            copy.draw(slice)
        }
    }
}

private struct TypingAnimation: CustomAnimation {
    var text: String
    var pauseIntensity: TypingTextConfig.PauseIntensity
    var duration: TimeInterval
    nonisolated func animate<V>(
        value: V,
        time: TimeInterval,
        context _: inout AnimationContext<V>
    ) -> V? where V: VectorArithmetic {
        let textCount = CGFloat(text.count)
        guard time <= duration else { return nil }

        let timeProgress = time / duration
        let index = floor(timeProgress * textCount)
        let currentProgress = (timeProgress * textCount) - index

        /// Each character has an individual animation value that progress from 0 to 1
        /// When the pause Intensity is 0, animate smoothly for the entire duration
        /// When pause Intensity is 0.5, each character pause from 0...0.5 then animate from 0.5...1
        /// When pause Intensity is 1, each character pause from 0...1 then update instantly without animation
        let pause = pauseIntensity.rawValue
        if currentProgress < pause {
            return value.scaled(by: index / textCount)
        }
        let newValue = (index + (currentProgress - pause) / (1 - pause)) / textCount
        return value.scaled(by: newValue)
    }
}

private extension Animation {
    static func typingAnimation(
        text: String,
        pause: TypingTextConfig.PauseIntensity,
        duration: TimeInterval
    ) -> Animation {
        Animation(TypingAnimation(text: text, pauseIntensity: pause, duration: duration))
    }
}

@Observable
private class HapticsManager {
    var engine: CHHapticEngine?

    func prepareEngine() {
        #if !targetEnvironment(simulator)
            guard engine == nil else { return }
            do {
                engine = try CHHapticEngine()
                try engine?.start()
            } catch {
                print(error.localizedDescription)
            }
        #endif
    }

    func stopEngine() async {
        #if !targetEnvironment(simulator)
            guard let engine else { return }
            do {
                try await engine.stop()
                self.engine = nil
            } catch {
                print(error.localizedDescription)
            }
        #endif
    }

    func playHaptics(text: String, duration: CGFloat, forDismiss: Bool) throws {
        guard let engine else { return }
        let indices = (0 ..< text.count)
        let delay = duration / CGFloat(indices.count)

        var events: [CHHapticEvent] = []

        if forDismiss {
            events = [
                CHHapticEvent(eventType: .hapticContinuous, parameters: [
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2),
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.1),
                ], relativeTime: 0, duration: duration),
            ]
        } else {
            events = indices.compactMap { index in
                CHHapticEvent(eventType: .hapticTransient, parameters: [
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5),
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                ], relativeTime: CGFloat(index) * delay)
            }
        }

        let pattern = try CHHapticPattern(events: events, parameters: [])
        let player = try engine.makePlayer(with: pattern)
        try player.start(atTime: CHHapticTimeImmediate)
    }
}
