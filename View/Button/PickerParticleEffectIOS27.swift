//
//  PickerParticleEffectIOS27.swift
//  animation
//
//  Created on 8/23/26.
//
//  Learning notes — a reaction picker with an emoji particle burst.
//
//  Three pieces compose:
//
//  1. `ReactionPicker` wraps any label in a glass capsule and presents the row in a
//     popover. The label doubles as the `matchedTransitionSource`, which is what lets
//     the popover zoom out of it instead of fading in.
//  2. `ReactionView` is that row. It pops reactions in one at a time by appending to
//     `staggeredContent`; each row reads its own membership to drive `scaleEffect`.
//  3. `ParticleEmitterAnimator` rides in an overlay on the label and replays a burst of
//     the picked emoji every time `selection` changes. See its doc comment for how the
//     single keyframe timeline is sliced into per-particle lifetimes.

import SwiftUI

@available(iOS 27.0, *)
struct PickerParticleEffectIOS27Demo: View {
    @State private var selectedReaction: Character?
    let reactions: [Character] = ["🐾", "🐕", "🧿", "👹", "🐶", "🪢"]
    var body: some View {
        NavigationStack {
            VStack {
                ReactionPicker(
                    reactions: reactions,
                    selection: $selectedReaction
                ) {
                    ZStack {
                        if let selectedReaction {
                            Text(String(selectedReaction))
                                .transition(.blurReplace())
                        } else {
                            Image(systemName: "face.smiling")
                                .transition(.blurReplace())
                        }
                    }
                    .font(.title3)
                    .foregroundStyle(.primary)
                    .frame(width: 45, height: 45)
                    .animation(.smooth, value: selectedReaction)
                }
            }
            .padding()
            .navigationTitle("Reaction Picker")
        }
    }
}

/// A glass capsule that presents a row of reactions in a popover and bursts the chosen one
/// upward out of the label.
///
/// ```swift
/// ReactionPicker(reactions: ["🐾", "🐕"], selection: $selectedReaction) {
///     Text(selectedReaction.map(String.init) ?? "🙂")
///         .frame(width: 45, height: 45)
/// }
/// ```
///
/// - Parameters:
///   - forcePopover: `true` presents with `.automatic`; `false` zooms the popover out of
///     the label via `matchedTransitionSource`. Also shortens the row's lead-in, since
///     there is no zoom to wait for.
///   - addsInsertButton: Appends a `plus.circle.fill` slot that reports `onInsertTapped`
///     instead of selecting a reaction.
///   - reactions: Displayed in order, capped to the six slots that fit the popover row.
///     Must be unique — rows are identified by value.
///   - label: Content of the capsule. Sized by the caller; the emitter scales its
///     particles to half the label's height.
@available(iOS 27.0, *)
struct ReactionPicker<Label: View>: View {
    var forcePopover: Bool = true
    var addsInsertButton: Bool = true
    var reactions: [Character]
    @Binding var selection: Character?
    @ContentBuilder var label: Label
    var onInsertTapped: () -> Void = {}
    /// View Properties
    @State private var showPopover: Bool = false
    @Namespace private var animation
    var body: some View {
        label
            .contentShape(.capsule)
            .matchedTransitionSource(id: "SOURCE", in: animation)
            .glassEffect(.regular.interactive(), in: .capsule)
            .overlay {
                GeometryReader {
                    particleEmitterAnimator($0.size)
                }
            }
            .onTapGesture {
                showPopover = true
            }
            .popover(isPresented: $showPopover) {
                ReactionView(forcePopover: forcePopover, addsInsertButton: addsInsertButton, reactions: reactions) { reaction in
                    selection = reaction
                    showPopover = false
                } onInsertTapped: {
                    showPopover = false
                    onInsertTapped()
                }
                .presentationCompactAdaptation(.popover)
                .navigationTransition(
                    forcePopover ? AnyNavigationTransition(.automatic) :
                        AnyNavigationTransition(.zoom(sourceID: "SOURCE", in: animation))
                )
            }
    }

    /// Emoji burst drawn in an overlay on the label, replayed whenever `selection` changes.
    ///
    /// One linear keyframe drives every particle. `progress` sweeps `0 ..< count + 3` and each
    /// particle subtracts its own index from it, so particle `i` stays dormant until `progress`
    /// reaches `i` — that offset is what staggers the launches out of a single timeline. Its
    /// local `currentProgress` then runs `0 ... 4`, sliced into:
    ///
    /// - `0 ... 0.5` scale up from nothing, anchored at the bottom so it grows out of the label
    /// - `0 ... 4` rise 35pt per unit (140pt total), fanned left/right by half a font size
    /// - `3 ... 4` fade out
    ///
    /// Hence the `count + 3` end value: the last particle launches at `count - 1` and needs 4
    /// more units to finish. At `count: 5` / `duration: 2.5` a unit is ~0.31s, so each particle
    /// lives ~1.25s and the burst overlaps 5 of them.
    ///
    /// - Parameter size: The label's size, from the enclosing `GeometryReader`. Particles are
    ///   half its height and the whole emitter is lifted by that much so they start at its top.
    @ContentBuilder
    private func particleEmitterAnimator(_ size: CGSize) -> some View {
        let count = 5
        let duration: CGFloat = 2.5
        let fontSize: CGFloat = size.height / 2

        KeyframeAnimator(initialValue: CGFloat.zero, trigger: selection) { progress in
            ZStack {
                // Nothing to burst before a first pick, and the timeline also runs once on
                // appearance — without this guard that pass would emit a placeholder.
                if let selection {
                    ForEach(0 ..< count, id: \.self) { index in
                        let currentProgress = progress < CGFloat(index) ? 0 : min(progress - CGFloat(index), 4)
                        let opacity = currentProgress > 3 ? (currentProgress - 3) / 1 : 0
                        let scaleProgress = currentProgress < 0.5 ? (currentProgress / 0.5) : 1
                        Text(String(selection))
                            .font(.system(size: fontSize))
                            .opacity(1 - opacity)
                            .scaleEffect(scaleProgress, anchor: .bottom)
                            .offset(x: index % 2 == 0 ? -fontSize / 2 : fontSize / 2)
                            .offset(y: currentProgress * -35)
                    }
                }
            }
        } keyframes: { _ in
            MoveKeyframe(0)
            LinearKeyframe(CGFloat(count + 3), duration: duration)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .offset(y: -fontSize)
    }
}

/// The popover row.
///
/// Rows pop in one at a time: `staggeredContent` grows by one entry per tick and each row reads
/// its own membership, so a single `withAnimation` per append gives every row its own spring
/// rather than animating the row as a block.
private struct ReactionView: View {
    var forcePopover: Bool
    var addsInsertButton: Bool
    var reactions: [Character]
    var onTap: (Character) -> Void
    var onInsertTapped: () -> Void
    /// View Properties
    @State private var isAnimated: Bool = false
    @State private var staggeredContent: [Character] = []

    var body: some View {
        // Six slots fit the popover row; the insert button claims one of them.
        let limited = Array(reactions.prefix(addsInsertButton ? 5 : 6))
        HStack(spacing: 0) {
            ForEach(limited, id: \.self) { reaction in
                let isVisible = staggeredContent.contains(reaction)
                Text(String(reaction))
                    .font(.system(size: 26))
                    .scaleEffect(isVisible ? 1 : 0.01, anchor: .leading)
                    .frame(width: 60, height: 45)
                    .contentShape(.rect)
                    .onTapGesture {
                        onTap(reaction)
                    }
            }

            if addsInsertButton {
                let isVisible = staggeredContent.contains("+")

                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(.gray)
                    .scaleEffect(isVisible ? 1 : 0.01, anchor: .leading)
                    .frame(width: 60, height: 45)
                    .contentShape(.rect)
                    .onTapGesture {
                        onInsertTapped()
                    }
            }
        }
        .padding(.horizontal, 5)
        .task {
            guard !isAnimated else { return }
            isAnimated = true

            // A zoom transition is still expanding the popover for roughly a third of a
            // second, so the stagger has to sit behind it or it plays mid-zoom. `.automatic`
            // has nothing to wait for.
            try? await Task.sleep(for: forcePopover ? .seconds(0.05) : .seconds(0.3))

            for reaction in limited + (addsInsertButton ? ["+"] : []) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.4, blendDuration: 0)) {
                    staggeredContent.append(reaction)
                }
                // `Task.sleep` is relative, so the gap must be a constant per iteration —
                // scaling it by the index would compound into an ever-slowing stagger.
                try? await Task.sleep(for: .seconds(0.03))
            }
        }
    }
}

@available(iOS 27.0, *)
#Preview {
    PickerParticleEffectIOS27Demo()
}
