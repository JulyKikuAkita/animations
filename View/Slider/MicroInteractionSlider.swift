//
//  MicroInteractionSlider.swift
//  animation
//
//  Learning point
//  ──────────────
//  "Slide to confirm" payment-style slider: a knob inside a capsule
//  that the user drags right to commit an action (Apple Pay, Uber,
//  iOS lock-screen power). When released past threshold the slider
//  shrinks, the chevron morphs into a checkmark, and the label swaps
//  to a confirmation. Polished iOS-26-style "micro-interaction" feel.
//
//  Five reusable mechanics
//  ───────────────────────
//    1. **Progress-driven everything** —
//       `progress = isCompleted ? 1 : (offsetX / maxLimit)` is the
//       single source of truth. Tint capsule width, knob icon
//       opacity/blur, and trailing label mask all derive from it.
//    2. **Cross-fading icons via opacity + blur** — chevron and
//       checkmark are STACKED in the knob; both have opacity tied to
//       progress AND a blur that's the inverse. So as the chevron
//       fades it also blurs OUT, while the checkmark fades in AND
//       sharpens. Perceptually smoother than a hard swap.
//    3. **Width-mask gating for the leading text** —
//       `Rectangle().scale(x: progress, anchor: .leading)` masks the
//       payment label so it's REVEALED behind the growing tint
//       capsule, not awkwardly overlapping it.
//    4. **`.containerRelativeFrame` for adaptive width** — the slider
//       takes 80% of its container while idle but only 50% when
//       completed. The shrink animates as part of the same
//       `withAnimation(.smooth)` block.
//    5. **`visualEffect` shimmer** — the idle-state hint label gets
//       a moving rectangle masked to the text bounds with
//       `.softLight` blend, an infinite linear repeat. Only paints
//       on the trailing text; once the user starts dragging, the mask
//       (which is `scale(x: 1 - progress)`) cuts it off naturally.
//
//  Why `containerRelativeFrame` instead of explicit frames
//  ──────────────────────────────────────────────────────
//  The slider needs to shrink to half-size on completion AND
//  re-centre. Hard-coded widths would have to recompute the offset
//  each step. `containerRelativeFrame { value, _ in ratio * value }`
//  re-derives width from the parent each frame, so the shrink
//  animation is just "change ratio" — SwiftUI handles geometry.
//
//  Why `visualEffect` for the shimmer
//  ──────────────────────────────────
//  `visualEffect { content, proxy in ... }` reads its own size
//  without spawning a `GeometryReader` (which would interfere with
//  intrinsic-content-size sizing of the surrounding `Text`). The
//  `[animateText]` capture list is required so the closure
//  re-evaluates when the flag flips.
//
//  Key APIs
//  ────────
//  • `@State` + `withAnimation(.smooth)` — coordinated multi-property
//    state transitions.
//  • `.containerRelativeFrame(.horizontal) { ... }` — adaptive width.
//  • `.visualEffect { content, proxy in ... }` — geometry reads
//    without GeometryReader.
//  • `.mask { Rectangle().scale(x: progress, anchor: .leading) }` —
//    horizontal reveal/hide via masking.
//  • `.allowsHitTesting(!isCompleted)` — disable interaction once
//    confirmed.
//
//  How to apply
//  ────────────
//  Use anywhere a high-stakes action wants a "deliberate confirm" UX:
//  payments, dangerous deletes, account closures. The
//  progress-as-single-source pattern is the architectural lesson —
//  most slider UIs end up easier to maintain when every visual derives
//  from one normalised value.
//

import SwiftUI

struct MicroInteractionSliderView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()

                let config = MicroInteractionSlider.Config(
                    idleText: "Swipe to confirm",
                    onSwipeText: "Confirms Payment",
                    confirmationText: "Success!",
                    tint: .green,
                    foregroundColor: .white
                )

                MicroInteractionSlider(config: config) {}
            }
            .padding(15)
            .navigationTitle(Text("Slide to Confirm"))
        }
    }
}

struct MicroInteractionSlider: View {
    var config: Config
    var onSwiped: () -> Void
    /// View Properties
    @State private var animateText: Bool = false
    @State private var offsetX: CGFloat = 0
    @State private var isCompleted: Bool = false
    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let knobSize = size.height
            let maxLimit = size.width - knobSize
            let progress: CGFloat = isCompleted ? 1 : (offsetX / maxLimit)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(
                        .gray.opacity(0.25)
                            .shadow(.inner(color: .black.opacity(0.2), radius: 10))
                    )

                /// Tint Capsule
                let extraCapsuleWidth = (size.width - knobSize) * progress
                Capsule()
                    .fill(config.tint.gradient)
                    .frame(width: knobSize + extraCapsuleWidth, height: knobSize)
                leadingTextView(size, progress: progress)

                HStack(spacing: 0) {
                    knobView(size, progress: progress, maxLimit: maxLimit)
                        .zIndex(1)
                        .scaleEffect(isCompleted ? 0.6 : 1, anchor: .center)

                    shimmerTextView(size, progress: progress)
                }
            }
        }
        .frame(height: isCompleted ? 50 : config.height)
        .containerRelativeFrame(.horizontal) { value, _ in
            let ratio: CGFloat = isCompleted ? 0.5 : 0.8
            return value * ratio
        }
        .frame(maxWidth: 300)
        .allowsHitTesting(!isCompleted)
    }

    func knobView(_ size: CGSize, progress: CGFloat, maxLimit: CGFloat) -> some View {
        Circle()
            .fill(.background)
            .padding(6)
            .frame(width: size.height, height: size.height)
            // Tip: opacity + inverse blur = perceptual "morph".
            // Stack two icons; tie one's opacity to `progress`, the
            // other to `1 - progress`. Crucially, blur each by the
            // OPPOSITE: the fading icon also de-focuses (high blur),
            // the appearing icon sharpens. The eye reads this as a
            // single blob morphing rather than two icons cross-fading.
            .overlay {
                ZStack {
                    Image(systemName: "chevron.right")
                        .opacity(1 - progress)
                        .blur(radius: progress * 10)

                    Image(systemName: "checkmark")
                        .opacity(progress)
                        .blur(radius: (1 - progress) * 10)
                }
                .font(.title3.bold())
            }
            .contentShape(.circle)
            .scaleEffect(isCompleted ? 0.6 : 1, anchor: .center)
            .offset(x: isCompleted ? maxLimit : offsetX)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        /// Limiting to end of the capsule
                        let knobSize = size.height
                        let maxLimit = size.width - knobSize
                        offsetX = min(max(value.translation.width, 0), maxLimit)
                    }.onEnded { _ in
                        if offsetX == maxLimit {
                            onSwiped()
                            /// Stopping shimmer effect
                            animateText = false

                            withAnimation(.smooth) {
                                isCompleted = true
                            }
                        } else {
                            withAnimation(.smooth) {
                                offsetX = 0
                            }
                        }
                    }
            )
    }

    func shimmerTextView(_ size: CGSize, progress: CGFloat) -> some View {
        Text(isCompleted ? config.confirmationText : config.idleText)
            .foregroundStyle(.gray.opacity(0.6))
            // Tip: the shimmer is a 90°-rotated rectangle (so it's
            // tall + thin) that slides horizontally past the text via
            // `visualEffect`'s `proxy.size.width` reads. Masked to the
            // text shape and blended with `.softLight` so it only
            // brightens within the letterforms.
            //
            // The `[animateText]` capture is REQUIRED — without it the
            // visualEffect closure won't re-run when the flag flips.
            .overlay {
                Rectangle()
                    .frame(height: 15)
                    .rotationEffect(.init(degrees: 90))
                    .visualEffect { [animateText] content, proxy in
                        content
                            .offset(x: -proxy.size.width * 1.8)
                            .offset(x: animateText ? proxy.size.width * 1.2 : 0)
                    }
                    .mask(alignment: .leading) {
                        Text(config.idleText)
                    }
                    .blendMode(.softLight)
            }
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            /// make it center
            /// Eliminating knob's radius
            .padding(.trailing, size.height / 2)
            // Tip: `Rectangle().scale(x: 1 - progress, anchor: .trailing)`
            // is the cleanest way to "wipe" content from one side.
            // As progress 0 → 1, scale 1 → 0 from the trailing anchor
            // — so the trailing label gets revealed from right to left
            // by the growing tint capsule. Inverse direction below.
            .mask {
                Rectangle()
                    .scale(x: 1 - progress, anchor: .trailing)
            }
            .frame(height: size.height)
            .task {
                withAnimation(Animation.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                    animateText = true
                }
            }
    }

    /// OnSwipe/Confirmation Text View
    func leadingTextView(_ size: CGSize, progress: CGFloat) -> some View {
        ZStack {
            Text(config.onSwipeText)
                .opacity(isCompleted ? 0 : 1)
                .blur(radius: isCompleted ? 10 : 0)

            Text(config.confirmationText)
                .opacity(!isCompleted ? 0 : 1)
                .blur(radius: !isCompleted ? 10 : 0)
        }
        .fontWeight(.semibold)
        .foregroundStyle(config.foregroundColor)
        .frame(maxWidth: .infinity)
        /// to make the view center
        .padding(.trailing, (size.height * (isCompleted ? 0.6 : 1)) / 2)
        .mask {
            Rectangle()
                .scale(x: progress, anchor: .leading)
        }
    }

    struct Config {
        let idleText: String
        let onSwipeText: String
        let confirmationText: String
        let tint: Color
        let foregroundColor: Color
        var height: CGFloat = 70
    }
}

#Preview {
    MicroInteractionSliderView()
}
