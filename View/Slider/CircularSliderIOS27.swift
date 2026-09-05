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

            knobView(isStart: true)

            knobView(isStart: false)
        }
        .compositingGroup()
        .padding(config.knobSize / 2)
        .frame(width: config.circleSize, height: config.circleSize)
        .onChange(of: isInteracting) { _, newValue in
            onInteractionChange(newValue)
        }
    }

    /// Knob view
    @ContentBuilder
    private func knobView(isStart: Bool) -> some View {
        let rotation = Angle(degrees: (isStart ? progress.0 : progress.1) * 360)
        let knobSize = config.knobSize - config.knobPadding

        Image(systemName: isStart ? config.knobStartSymbol : config.knobEndSymbol)
            .font(.system(size: knobSize / 2.5))
            .foregroundStyle(config.knobTint)
            .frame(width: knobSize, height: knobSize)
            /// reset icon rotation
            .rotationEffect(.init(degrees: 90))
            .rotationEffect(-rotation)
            .background(config.selectionTint, in: .circle)
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
                        let knobRadius = knobSize / 2
                        // TODO: add comment,  why use `atan2` here?
                        let radians = atan2(
                            vector.dy - knobRadius,
                            vector.dx - knobRadius
                        )
                        var angle = radians * 180 / .pi
                        if angle < 0 {
                            angle = 360 + angle
                        }
                        let angleProgress = angle / 360

                        /// limit slider length within the given limit length; and circle the slider if distance falls within the length
                        let other = isStart ? progress.1 : progress.0
                        let diff = abs(angleProgress - other)
                        let distance = min(diff, 1 - diff)

                        if distance < config.minimumLimitProgress {
                            let delta = angleProgress - (isStart ? progress.0 : progress.1)

                            progress.0 = (progress.0 + delta + 1).truncatingRemainder(dividingBy: 1)
                            progress.1 = (progress.1 + delta + 1).truncatingRemainder(dividingBy: 1)
                        } else if isStart {
                            progress.0 = angleProgress
                        } else {
                            progress.1 = angleProgress
                        }
                    }
            )
            .rotationEffect(.init(degrees: -90))
    }

    /// Stoke & ticks view with Canvas
    ///  TODO: add comment to introduce what Canvas is, pros&cons to draw with Canvas
    @ContentBuilder
    private func tickersView() -> some View {
        Canvas {
            context,
                size in
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
            let strokedClipShape = strokedPath.strokedPath(.init(lineWidth: lineWidth, lineCap: .round))

            var strokeContext = context
            strokeContext.fill(strokedClipShape, with: .color(config.selectionTint))
            /// Clipping Shape
            strokeContext.clip(to: strokedClipShape)

            /// Tick Marks
            for index in 0 ..< tickCount {
                var ctx = strokeContext
                let rotation = (Double(index) / Double(tickCount)) * 360

                ctx.translateBy(x: center.x, y: center.y)
                ctx.rotate(by: .degrees(rotation))

                let rect = CGRect(
                    x: radius - (tickWidth / 2),
                    y: -tickHeight / 2,
                    width: tickWidth,
                    height: tickHeight
                )

                ctx.fill(
                    Path(roundedRect: rect, cornerRadius: tickHeight / 2),
                    with: .color(config.tickTint)
                )
            }
        }
        .padding(-config.knobSize / 2)
        .rotationEffect(.init(degrees: -90))
    }
}

#Preview {
    CircularSliderIOS27Demo()
}
