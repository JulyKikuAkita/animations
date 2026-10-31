//
//  FireworkEffects.swift
//  animation
//
//  Created on 10/27/26.

// Learning notes — drawing with Canvas / GraphicsContext / Path (see `Fireworks`):
// 1. Canvas is immediate-mode drawing: one view whose closure
//    `{ (ctx: inout GraphicsContext, size: CGSize) in ... }` paints pixels directly.
//    Hundreds of sparks become draw calls, not hundreds of SwiftUI views, so there is
//    no per-element layout, diffing, or hit-testing cost. Coordinates are points with
//    the origin at the top-left; `size` is the canvas size to lay things out against.
// 2. Canvas does not animate on its own. Wrapping it in `TimelineView(.animation)`
//    re-runs the closure every display frame and supplies `timeline.date`; the drawing
//    is a pure function of that time (no @State).
// 3. Path is only geometry — it draws nothing until handed to the context.
//    Build it with the closure form (`Path { $0.move(to:); $0.addLine(to:) }`) for the
//    rocket trail, or a convenience init (`Path(ellipseIn:)`) for spark dots (`circle`).
// 4. GraphicsContext draws a path with `fill(_:with:)` or `stroke(_:with:lineWidth:)`.
//    `with:` takes a `GraphicsContext.Shading`: `.color(...)` for sparks,
//    `.linearGradient(_:startPoint:endPoint:)` for the trail, and
//    `.radialGradient(_:center:startRadius:endRadius:)` for the center flash.
//    Unlike the LinearGradient view, these points are absolute canvas coordinates,
//    so the trail gradient can run exactly from `tail` to `head`.
// 5. GraphicsContext is a value type holding drawing state (blendMode, opacity,
//    transform, filters) that targets the same underlying canvas. A copy inherits the
//    current state and still draws to that canvas, so `var local = ctx;
//    local.translateBy(...)` scopes a state change to one group of draws.
//    `inout` (as in the helpers here) is only required when a callee must mutate
//    state the caller keeps using; the draw calls themselves don't need it.
// 6. Draws are painted in call order (later on top). Setting
//    `ctx.blendMode = .plusLighter` once makes overlapping sparks add their light
//    instead of covering each other — the glow on a black background.
//    `ctx.addFilter(.blur(radius:))` is the next step for a softer glow.
// 7. Effect math, briefly: `random(_:)` is a stateless `fract(sin(x) * 43758.5453)` hash
//    seeded per cycle, so each firework gets new colors/locations every loop without
//    storage; the burst uses ease-out-quart radius `1 - (1 - p)^4`, `p^2` gravity drop,
//    `1 - p` fade, and a per-spark `sin` twinkle.

import SwiftUI

struct FireworkDemo: View {
    var body: some View {
        Fireworks(
            colors: [.green, .purple, .indigo, .red, .pink, .yellow, .cyan, .orange],
            rocketDuration: 1.0,
            burstDuration: 2.0
        )
        .frame(height: 480)
        .background {
            RoundedRectangle(cornerRadius: 30)
                .fill(.black)
        }
        .padding()
    }
}

struct Fireworks: View {
    var colors: [Color]
    var burstCount = 6
    var burstColor: Color = .orange
    var sparksPerBurst = 120
    var sparkSize = 1.0
    /// half view height
    var burstSize = 0.8
    var rocketDuration = 0.5
    var burstDuration = 1.5

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            Canvas { ctx, size in
                ctx.blendMode = .plusLighter

                for index in 0 ..< burstCount {
                    drawFirework(
                        index: index,
                        time: time,
                        ctx: &ctx,
                        size: size
                    )
                }
            }
        }
    }

    private func drawFirework(
        index: Int,
        time: TimeInterval,
        ctx: inout GraphicsContext,
        size: CGSize
    ) {
        let pause = CGFloat(index) * 0
        let cycleLength = rocketDuration + burstDuration + pause
        let cycle = time / cycleLength + CGFloat(index) * 0.37
        let elapsed = (cycle - floor(cycle)) * cycleLength
        let randomBase = CGFloat(index) * 100 + floor(cycle)

        // colors
        let colorCount = CGFloat(colors.count)
        let primaryColor = colors[Int(random(randomBase + 1) * colorCount)]
        let secondaryColor = colors[Int(random(randomBase + 2) * colorCount)]

        let location: CGPoint = .init(
            x: random(randomBase + 3) * size.width,
            y: (0.1 + 0.8 * random(randomBase + 4)) * size.height
        )

        if elapsed < rocketDuration {
            let startLocation = CGPoint(
                x: location.x + (random(randomBase + 5) - 0.5) * size.width * 0.3,
                y: size.height
            )
            // Drawing Rocket
            drawRocket(
                from: startLocation,
                to: location,
                progress: elapsed / rocketDuration,
                color: primaryColor,
                ctx: &ctx
            )
        } else if elapsed < rocketDuration + burstDuration {
            // Drawing Burst
            drawBursts(
                center: location,
                progress: (elapsed - rocketDuration) / burstDuration,
                primaryColor: primaryColor,
                secondaryColor: secondaryColor,
                burstColor: burstColor,
                randomBase: randomBase,
                time: time,
                context: &ctx,
                size: size
            )
        }
    }

    private func drawRocket(
        from: CGPoint,
        to: CGPoint, // swiftlint:disable:this identifier_name
        progress: CGFloat,
        color: Color,
        ctx: inout GraphicsContext
    ) {
        let head = rocketPosition(at: progress, start: from, end: to)
        let tail = rocketPosition(at: max(0, progress - 0.3), start: from, end: to)

        let tailShape = Path { path in
            path.move(to: tail)
            path.addLine(to: head)
        }

        ctx.stroke(
            tailShape,
            with: .linearGradient(Gradient(colors: [.clear, color]), startPoint: tail, endPoint: head),
            lineWidth: sparkSize * 0.9
        )

        // head circle
        ctx.fill(circle(at: head, radius: sparkSize * 0.6), with: .color(.white))
    }

    // swiftlint:disable:next function_parameter_count
    private func drawBursts(
        center: CGPoint,
        progress: CGFloat,
        primaryColor: Color,
        secondaryColor: Color,
        burstColor: Color,
        randomBase: Double,
        time: Double,
        context: inout GraphicsContext,
        size: CGSize
    ) {
        let radiusRandom = (0.4 + 0.4 * random(randomBase + 0.6)) * (1 - pow(1 - progress, 4))
        let radius = size.height * burstSize * radiusRandom
        let fade = 1 - progress
        let drop = progress * progress * size.height * 0.07

        // Center Flas
        if progress < 0.15 {
            let flashRadius = size.height * 0.35 * burstSize
            context.fill(
                circle(at: center, radius: flashRadius),
                with: .radialGradient(
                    Gradient(colors: [burstColor.opacity(1 - progress / 0.15), .clear]),
                    center: center, startRadius: 0, endRadius: flashRadius
                )
            )
        }

        // Sparks
        for index in 0 ..< sparksPerBurst {
            let value = random(randomBase + Double(index) * 7.1)
            let angle = random(randomBase + Double(index) * 3.3) * 2 * .pi
            let distance = radius * pow(value, 0.3)
            let twinkle = 0.4 + 0.6 * abs(sin(time * (6 + 12 * value) + value * 40))

            let point = CGPoint(x: center.x + cos(angle) * distance,
                                y: center.y + sin(angle) * distance + drop)

            let sparkColor = index % 3 == 0 ? secondaryColor : primaryColor
            context.fill(
                circle(at: point, radius: sparkSize),
                with: .color(sparkColor.opacity(fade * twinkle))
            )
        }
    }

    private func circle(at center: CGPoint, radius: Double) -> Path {
        Path(ellipseIn: CGRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        ))
    }

    // swiftlint:disable:next identifier_name
    private func rocketPosition(at t: Double, start: CGPoint, end: CGPoint) -> CGPoint {
        let eased = UnitCurve.easeOut.value(at: t)
        return CGPoint(
            x: start.x + (end.x - start.x) * eased,
            y: start.y + (end.y - start.y) * eased
        )
    }

    private func random(_ base: CGFloat) -> CGFloat {
        let value = sin(base * 12.9898) * 43758.5453
        return value - floor(value)
    }
}

#Preview {
    FireworkDemo()
}
