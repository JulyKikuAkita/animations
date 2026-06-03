//
//  FlipClockTextEffectView.swift
//  animation
//
//  Learning point
//  ──────────────
//  Mechanical flip-clock digit (top half "falls" forward, revealing the
//  next digit underneath). Each cell is THREE rotated rects layered on
//  top of each other:
//    • Bottom half — shows the CURRENT digit (lower mask).
//    • Top half (static) — pre-renders the NEXT digit (upper mask), so
//      it's already there when the flap falls away.
//    • Top half (animated) — the actual flap. Rotates around its bottom
//      edge with `rotation3DEffect`, swapping its painted text from
//      current → next once it's past 90° (because past 90° you see the
//      *back* of the rotated view, mirrored).
//
//  Why a custom `Animatable` modifier?
//  ──────────────────────────────────
//  SwiftUI animates the rotation, but `Text("\(value)")` content swaps
//  instantly. We need to swap the painted character at the precise
//  midpoint of the rotation (90°). The `RotationModifier`'s
//  `animatableData` is the rotation angle itself, and its body picks
//  current vs next text based on whether `-rotation > 90`.
//
//  The `scaleEffect(x: 1, y: -1)` on the >90° branch flips the text
//  vertically — without it, the user would see the digit upside down
//  because the flap is now showing its back face.
//
//  Key APIs
//  ────────
//  • `rotation3DEffect(angle:axis:anchor:perspective:)` — the flip;
//    `anchor: .bottom` = pivot at the seam between halves.
//  • `withAnimation(.easeInOut, completionCriteria: .logicallyComplete) { ... } completion:`
//    — fire a closure when the animation visually completes (iOS 17+).
//  • `Animatable` + `animatableData` — frame-by-frame access to the
//    interpolated rotation so we can swap content mid-flip.
//  • `UnevenRoundedRectangle` — round only the corners we want (top-only
//    for the upper half, bottom-only for the lower).
//  • `.drawingGroup()` — flatten the text + clip to a single bitmap so
//    the rotation transform is GPU-cheap.
//
//  How to apply
//  ────────────
//  Use whenever you want a physical-looking digit/character flip.
//  Same trick generalises to flipping cards, calendars, or any
//  before/after split-axis transition.
//
//  See also
//  ────────
//  • DynamicFloatingSheetsiOS18View.swift — uses
//    `.contentTransition(.numericText())`, the *easy* way to animate
//    digit changes when you don't need the mechanical flap look.
//

import SwiftUI

struct FlipClockTextEffectDemoView: View {
    @State private var count: Int = 0
    @State private var seconds: Int = 0
    @State private var timer: CGFloat = 0
    let countdownReset: CGFloat = 60
    var body: some View {
        NavigationStack {
            VStack {
                timerCountDownView()

                Button("Update") {
                    count += 1
                }
                .padding(.top, 45)
                FlipClockTextEffectView(
                    value: $count,
                    size: CGSize(width: 100, height: 150),
                    fontSize: 70,
                    cornerRadius: 10,
                    foreground: .white,
                    background: .green
                )
            }
            .padding()
        }
    }

    @ViewBuilder
    func timerCountDownView() -> some View {
        HStack(spacing: 4) {
            FlipClockTextEffectView(
                value: .constant(seconds / 10),
                size: CGSize(width: 100, height: 150),
                fontSize: 70,
                cornerRadius: 10,
                foreground: .white,
                background: .brown
            )

            FlipClockTextEffectView(
                value: .constant(seconds % 10),
                size: CGSize(width: 100, height: 150),
                fontSize: 70,
                cornerRadius: 10,
                foreground: .white,
                background: .orange
            )
        }
        .onReceive(Timer.publish(every: 0.01, on: .current, in: .common).autoconnect(), perform: { _ in
            timer += 0.01
            if timer >= countdownReset { timer = 0 }
            seconds = Int(timer)
        })
    }
}

struct FlipClockTextEffectView: View {
    @Binding var value: Int
    /// Config
    var size: CGSize
    var fontSize: CGFloat
    var cornerRadius: CGFloat
    var foreground: Color
    var background: Color
    var animationDuration: CGFloat = 0.8

    /// View Properties
    @State private var nextValue: Int = 0
    @State private var currentValue: Int = 0
    @State private var rotation: CGFloat = 0

    var body: some View {
        let halfHeight = size.height * 0.5
        ZStack {
            UnevenRoundedRectangle(
                topLeadingRadius: cornerRadius,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: cornerRadius
            )
            .fill(background.shadow(.inner(radius: 1)))
            .frame(height: halfHeight)
            .overlay(alignment: .top) {
                textView(nextValue)
                    .frame(width: size.width, height: size.height)
                    .drawingGroup()
            }
            .clipped()
            .frame(maxHeight: .infinity, alignment: .top)

            UnevenRoundedRectangle(
                topLeadingRadius: cornerRadius,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: cornerRadius
            )
            .fill(background.shadow(.inner(radius: 1)))
            .frame(height: halfHeight)
            .modifier(
                RotationModifier(
                    rotation: rotation,
                    currentValue: currentValue,
                    nextValue: nextValue,
                    fontSize: fontSize,
                    foreground: foreground,
                    size: size
                )
            )
            .clipped()
            .rotation3DEffect(
                .init(degrees: rotation),
                axis: (x: 1.0, y: 0.0, z: 0.0),
                anchor: .bottom,
                anchorZ: 0,
                perspective: 0.4
            )
            .frame(maxHeight: .infinity, alignment: .top)
            .zIndex(10)

            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: cornerRadius,
                bottomTrailingRadius: cornerRadius,
                topTrailingRadius: 0
            )
            .fill(background.shadow(.inner(radius: 1)))
            .frame(height: halfHeight)
            .overlay(alignment: .bottom) {
                textView(currentValue)
                    .frame(width: size.width, height: size.height)
                    .drawingGroup()
            }
            .clipped()
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .frame(width: size.width, height: size.height)
        // Tip: drive the flip from `value`, not from button taps.
        // Setting `currentValue = oldValue` and `nextValue = newValue`
        // BEFORE the animation starts means both halves are pre-painted
        // with the right digits; the rotation then reveals them.
        // Once rotation lands at -180°, snap to 0 and bake the new digit
        // into `currentValue`. The `rotation == 0` guard prevents the
        // animation from being re-entered if `value` updates mid-flip.
        .onChange(of: value, initial: true) { oldValue, newValue in
            currentValue = oldValue
            nextValue = newValue

            guard rotation == 0 else { /// prevent interrupt flip animation
                currentValue = newValue
                return
            }

            guard oldValue != newValue else { return }

            // `completionCriteria: .logicallyComplete` (iOS 17+) — the
            // completion closure runs when the animation visually
            // finishes, even if a new one starts. Avoids the old hack of
            // sleeping for `duration` then committing.
            withAnimation(.easeInOut(duration: animationDuration), completionCriteria: .logicallyComplete) {
                rotation = -180
            } completion: { /// update value and rotation when the flip animation finishes
                rotation = 0
                currentValue = value
            }
        }
    }

    @ViewBuilder
    func textView(_ value: Int) -> some View {
        Text("\(value)")
            .font(.system(size: fontSize).bold())
            .foregroundStyle(foreground)
            .lineLimit(1)
    }
}

/// when rotate > 90 degrees, the text content needs to updated to the next value
/// since default swiftUI behavior is the end value will be directly reflected rather than progression
/// we need to use animatableData to progressively update the value from start to end
private struct RotationModifier: ViewModifier, Animatable {
    var rotation: CGFloat
    var currentValue: Int
    var nextValue: Int
    var fontSize: CGFloat
    var foreground: Color
    var size: CGSize
    var animatableData: CGFloat {
        get { rotation }
        set { rotation = newValue }
    }

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                // Tip: the body is re-evaluated each frame because
                // `animatableData` interpolates `rotation`. Past 90° the
                // flap is showing its back face, so swap to `nextValue`
                // and apply `scaleEffect(x: 1, y: -1)` to un-mirror it.
                // `.transition(.identity)` prevents SwiftUI from
                // cross-fading the swap — we want a HARD cut at 90°.
                Group {
                    if -rotation > 90 {
                        Text("\(nextValue)")
                            .font(.system(size: fontSize).bold())
                            .foregroundStyle(foreground)
                            .scaleEffect(x: 1, y: -1) /// flip the view since it's been rotated
                            .transition(.identity)
                            .lineLimit(1)
                    } else {
                        Text("\(currentValue)")
                            .font(.system(size: fontSize).bold())
                            .foregroundStyle(foreground)
                            .transition(.identity)
                            .lineLimit(1)
                    }
                }
                .frame(width: size.width, height: size.height)
                .drawingGroup()
            }
    }
}

#Preview {
    FlipClockTextEffectDemoView()
}
