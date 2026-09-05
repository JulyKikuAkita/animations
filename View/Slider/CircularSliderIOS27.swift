//
//  CircularSliderIOS27.swift
//  animation
//
//  Created on 9/5/26.
//
// Apple Bedtime app circular slider
import SwiftUI

struct CircularSliderIOS27Demo: View {
    @State private var progress: (Double, Double) = (0, 0.5)
    var body: some View {
        VStack(spacing: 30) {
            HStack {
                TimeFromProgress(progress: progress.0)
                Spacer(minLength: 0)
                TimeFromProgress(progress: progress.1)
            }
            .padding(.horizontal, 30)

            CircularSlider(progress: $progress) {
                ClockView()
            } onInteractionChange: { inInteracting in
                print(inInteracting)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 25)
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 30))
        .padding(15)
    }
}

struct TimeFromProgress: View {
    var progress: CGFloat
    var body: some View {
        Text(timeString)
            .font(.title.bold())
    }

    /// convert progress to time value
    private var timeString: String {
        let totalMinutes = Int((progress * 24 * 60).rounded()) % (24 * 60)
        let hour = totalMinutes / 60
        let minute = totalMinutes % 60

        let period = hour < 12 ? "AM" : "PM"
        let displayHour = hour % 12 == 0 ? 12 : hour % 12
        return String(format: "%d:%02d %@", displayHour, minute, period)
    }
}

struct CircularSliderConfig {
    var knobStartSymbol: String = "alarm.fill"
    var knobEndSymbol: String = "bed.double.fill"

    var selectionTint: Color = .init(UIColor.systemGray5)
    var backgroundTint: Color = .init(UIColor.systemBackground)
    var knobTint: Color = .gray
    var knobSize: CGFloat = 52
    var knobPadding: CGFloat = 15
    var circleSize: CGFloat = 320

    var minimumLimitProgress: CGFloat = 0.1
    var tickTint: Color = .init(UIColor.systemBackground)
    var tickSpacing: CGFloat = 3
}

/// note:iOS 27 SDK, public typealias ContentBuilder = SwiftUICore::ViewBuilder
struct CircularSlider<Label: View>: View {
    var config: CircularSliderConfig = .init()
    /// (Start, End) given progress from (0-1)
    @Binding var progress: (Double, Double)
    @ContentBuilder var label: Label
    /// helper for before/after upates
    var onInteractionChange: (_ inInteracting: Bool) -> Void = { _ in }
    /// View Properties
    @GestureState private var isInteracting: Bool = false
    var body: some View {
        ZStack {
            Circle()
                .stroke(config.backgroundTint, lineWidth: config.knobSize)
                .overlay {
                    label
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipShape(.circle)
                        .padding(config.knobSize / 2)
                }

            tickersView()

            /// Knobs are real views stacked above the Canvas because Canvas drawings cannot receive
            /// gestures; the Canvas only renders the track it sits under.
            knobView(isStart: true)

            knobView(isStart: false)
        }
        /// Flattens the stack into one layer before the outer modifiers apply, so the knobs and the
        /// arc composite against each other rather than each blending with the backdrop separately.
        .compositingGroup()
        .shadow(color: .black.opacity(0.2), radius: 1)
        .padding(config.knobSize / 2)
        .frame(width: config.circleSize, height: config.circleSize)
        .onChange(of: isInteracting) { _, newValue in
            onInteractionChange(newValue)
        }
        .animation(.easeInOut(duration: 0.2), value: config.selectionTint)
    }

    /// Knob view
    ///
    /// Positioned with the same trigonometry-free trick as `ClockView`, but using `offset`
    /// instead of a stretched frame: push the knob out along its local +x axis by the ring
    /// radius, then rotate. Both `offset` and `rotationEffect` are render-time transforms that
    /// leave the layout frame untouched, so the knob's frame stays centered in the ZStack and
    /// that center is what `rotationEffect` pivots on — the offset knob sweeps the ring.
    ///
    /// Four rotations stack here and it is worth tracking why the glyph still ends up upright.
    /// In wrap order they are `+90°`, `-rotation`, `+rotation`, `-90°`: the inner pair cancels
    /// the progress rotation, and the outer pair cancels the -90° reorientation applied at the
    /// bottom of this chain. Net rotation on the symbol is zero at every progress value.
    @ContentBuilder
    private func knobView(isStart: Bool) -> some View {
        let rotation = Angle(degrees: (isStart ? progress.0 : progress.1) * 360)
        let knobSize = config.knobSize - config.knobPadding

        Image(systemName: isStart ? config.knobStartSymbol : config.knobEndSymbol)
            .font(.system(size: knobSize / 2.5))
            .foregroundStyle(config.knobTint)
            .frame(width: knobSize, height: knobSize)
            /// Cancels the outermost -90° below, which exists only to move progress 0 to the top.
            .rotationEffect(.init(degrees: 90))
            /// Cancels the progress rotation applied below, keeping the symbol upright while its
            /// position still travels around the ring.
            .rotationEffect(-rotation)
            .background(config.selectionTint, in: .circle)
            /// Displace along local +x by the ring radius. The circle is inset by half a knob on
            /// each side, so the knob's center lands on the track rather than the outer edge.
            .offset(x: (config.circleSize - config.knobSize) / 2)
            /// Actual rotation
            .rotationEffect(rotation)
            .gesture(
                DragGesture(minimumDistance: 5)
                    .updating($isInteracting) { _, out, _ in
                        out = true
                    }
                    .onChanged { value in
                        /// Transforming Gesture location into angle (0-360)
                        let vector = CGVector(dx: value.location.x, dy: value.location.y)
                        /// `value.location` arrives in the knob's own coordinate space, whose origin
                        /// is the knob's top-left, so subtracting the radius re-centers the vector
                        /// on the knob's center before measuring its direction.
                        let knobRadius = knobSize / 2
                        /// `atan2` is the inverse of the polar placement above: it turns a 2D vector
                        /// back into the angle that produced it. Plain `atan(dy/dx)` cannot do this —
                        /// dividing throws away the individual signs, so it only spans 180° and
                        /// cannot tell (+,+) from (-,-), and it divides by zero on a purely vertical
                        /// drag. `atan2` takes both components separately, so it keeps the quadrant,
                        /// covers the full circle, and is defined when dx is 0.
                        let radians = atan2(
                            vector.dy - knobRadius,
                            vector.dx - knobRadius
                        )
                        var angle = radians * 180 / .pi
                        /// `atan2` returns (-180°, 180°]; progress is a 0-1 fraction of a full turn,
                        /// so fold the negative half up into a single 0-360 range first.
                        if angle < 0 {
                            angle = 360 + angle
                        }
                        let angleProgress = angle / 360

                        /// limit slider length within the given limit length;
                        /// and circle the slider if distance falls within the length
                        let other = isStart ? progress.1 : progress.0
                        let diff = abs(angleProgress - other)
                        /// The track wraps, so the two knobs have two separating arcs; the shorter one
                        /// is the real gap. Without `min(diff, 1 - diff)` a pair straddling 0 (say 0.95
                        /// and 0.05) would measure as far apart instead of adjacent.
                        let distance = min(diff, 1 - diff)

                        if distance < config.minimumLimitProgress {
                            /// Pushing past the minimum gap drags the whole selection instead of
                            /// squashing it: apply this knob's delta to both ends so the arc keeps
                            /// its length and rotates as a unit.
                            let delta = angleProgress - (isStart ? progress.0 : progress.1)

                            /// `+ 1` before the remainder because `truncatingRemainder` keeps the sign
                            /// of the dividend, so a negative delta would otherwise yield a negative
                            /// progress instead of wrapping around to just under 1.
                            progress.0 = (progress.0 + delta + 1).truncatingRemainder(dividingBy: 1)
                            progress.1 = (progress.1 + delta + 1).truncatingRemainder(dividingBy: 1)
                        } else if isStart {
                            progress.0 = angleProgress
                        } else {
                            progress.1 = angleProgress
                        }
                    }
            )
            /// Rotates the whole knob so progress 0 sits at the top (12 o'clock) rather than at the
            /// +x axis where angle 0 naturally falls. Matches the -90° on `tickersView`.
            .rotationEffect(.init(degrees: -90))
    }

    /// Stoke & ticks view with Canvas
    ///
    /// `Canvas` is SwiftUI's immediate-mode drawing surface: instead of composing one view per
    /// element, it hands a `GraphicsContext` to a closure that paints paths directly, and the
    /// whole thing stays a single leaf view in the hierarchy.
    ///
    /// Why it fits here:
    /// - Around a hundred ticks (`circleSize / tickSpacing`) collapse into one view, skipping the
    ///   per-item layout, identity, and diffing work that a `ForEach` of shapes would incur.
    /// - `GraphicsContext.clip(to:)` accepts an arbitrary stroked path, which is what makes the
    ///   "ticks only visible inside the selected arc" effect nearly free: fill the arc, clip to
    ///   that same shape, then draw every tick and let the clip discard the ones outside.
    /// - A `GraphicsContext` is a value type, so `var ctx = strokeContext` is a cheap save/restore
    ///   of transform and clip state — each tick gets a fresh copy instead of undoing its rotation.
    ///
    /// What is given up:
    /// - The drawing is opaque to SwiftUI. Nothing inside is a view, so there is no hit-testing,
    ///   accessibility, or gesture attachment on individual ticks — which is exactly why the
    ///   draggable knobs are real views layered on top rather than part of this Canvas.
    /// - No view modifiers or implicit animation on individual elements; any change to the inputs
    ///   redraws the entire closure.
    private func tickersView() -> some View {
        Canvas { context, size in
            let tickCount = Int(config.circleSize / config.tickSpacing)
            let tickWidth = config.knobSize / 4
            let tickHeight: CGFloat = 2
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = (config.circleSize - config.knobSize) / 2

            let startAngle = Angle(degrees: progress.0 * 360)
            let endAngle = Angle(degrees: progress.1 * 360)
            let lineWidth = config.knobSize - config.knobPadding
            let strokedPath = Path { path in
                path.addArc(
                    center: center,
                    radius: radius,
                    startAngle: startAngle,
                    endAngle: endAngle,
                    clockwise: false
                )
            }
            /// `strokedPath` converts the thin arc into a filled outline of itself, so the band can
            /// serve as both the painted selection and the clip region. `.round` caps give the ends
            /// the same half-circle profile as the knobs sitting on them.
            let strokedClipShape = strokedPath.strokedPath(
                .init(lineWidth: lineWidth, lineCap: .round)
            )

            var strokeContext = context
            strokeContext.fill(strokedClipShape, with: .color(config.selectionTint))
            /// Clipping Shape
            strokeContext.clip(to: strokedClipShape)

            /// Tick Marks
            for index in 0 ..< tickCount {
                /// Copying the clipped context per tick inherits the clip while isolating the
                /// transform below, so each tick starts from an unrotated origin.
                var ctx = strokeContext
                let rotation = (Double(index) / Double(tickCount)) * 360

                /// The polar placement from `ClockView`, expressed as context transforms rather than
                /// view modifiers: move the origin to the dial center, spin the coordinate system,
                /// then draw the tick out along the local +x axis at `radius`.
                ctx.translateBy(x: center.x, y: center.y)
                ctx.rotate(by: .degrees(rotation))

                /// Both offsets are half-dimension so the tick straddles the point it marks: x
                /// centers it on the track radius, y centers it on the rotated axis.
                let rect = CGRect(
                    x: radius - (tickWidth / 2),
                    y: -tickHeight / 2,
                    width: tickWidth,
                    height: tickHeight
                )

                /// Ticks are drawn for the full 360°; the clip established above is what limits the
                /// visible ones to the selected arc, so no arc-membership test is needed here.
                ctx.fill(
                    Path(roundedRect: rect, cornerRadius: tickHeight / 2),
                    with: .color(config.tickTint)
                )
            }
        }
        /// Cancels the `knobSize / 2` padding applied to the parent ZStack, letting the Canvas span
        /// the full `circleSize` so its center matches the center the knobs rotate about.
        .padding(-config.knobSize / 2)
        /// Same 0-at-the-top reorientation as the knobs. Applied to the whole Canvas because
        /// `Path.addArc` and the tick transforms both measure angle 0 from the +x axis.
        .rotationEffect(.init(degrees: -90))
    }
}

#Preview {
    CircularSliderIOS27Demo()
}

/**
 atan2 = "arc tangent, 2 arguments."

 The 2 is the argument count, not a power or a variant — it's the two-argument form of arctangent,
 atan2(y, x) instead of atan(y/x). The name comes from Fortran, which introduced ATAN2 alongside ATAN,
 and it stuck: C's math.h, and from there essentially every language including Swift.

 That naming is the whole point of the function. atan receives one number —
 a ratio that has already collapsed y and x together, discarding which of them was negative.
 atan2 receives them still separated, so it can inspect both signs and recover the quadrant:

  │  y   │  x   │ y/x  │ atan(y/x)   │ atan2(y, x) │
  │ 1    │ 1     │ 1    │ 45°             │ 45°         │
  │ −1  │ −1  │ 1    │ 45°             │ −135°       │
  │ 1    │ 0    │ ∞   │ undefined │ 90°         │

 Rows 1 and 2 are opposite directions that atan cannot tell apart. Row 3 is the vertical drag that has no ratio at all.
 Hence the range difference: atan spans 180° (−90°…90°), atan2 spans the full 360° as (−180°, 180°] —
 which is why CircularSliderIOS27.swift only needs to fold the negative half up by 360 to get a clean 0–360 sweep.

 Argument order is worth remembering since it reads backwards from coordinate convention:
 y first, then x — matching the call in the drag handler, atan2(vector.dy - knobRadius, vector.dx - knobRadius).
 */
