//
//  MetaballAnimationView.swift
//  animation
//
//  Learning point
//  ──────────────
//  The pre-iOS-26 (Canvas-based) approach to metaballs — same
//  visual goal as `[[MetaballAnimation_iOS26]]` but using
//  `Canvas { context, size in ... context.addFilter(...) }` instead
//  of a custom Metal shader. Two demos:
//
//    • **Single** — a draggable ball that gloops away from a fixed
//      ball as you drag, snapping back as you release. Demonstrates
//      gesture-driven blob deformation.
//    • **Clubbed** — 15 random rectangles that collectively flow
//      together / apart on a tap, driven by a `TimelineView` that
//      ticks every 6.6 seconds.
//
//  How it works without a custom shader
//  ────────────────────────────────────
//  SwiftUI's `Canvas` exposes Core Image filters via
//  `context.addFilter(.blur(radius:))` and
//  `context.addFilter(.alphaThreshold(min:color:))`. Stacking them
//  in this order:
//
//    1. `addFilter(.alphaThreshold(min: 0.5, color: .white))` —
//       sharp cutoff: pixels with alpha ≥ 0.5 → opaque, else
//       transparent.
//    2. `addFilter(.blur(radius: 30))` — gaussian softening.
//
//  ...gives the metaball look without any Metal code. Note: Core
//  Image filters apply LIFO (last-added runs first per pixel), so
//  `addFilter(.blur)` AFTER `addFilter(.alphaThreshold)` means
//  blur runs FIRST, threshold runs SECOND — exactly the order we
//  want.
//
//  The gradient mask trick
//  ───────────────────────
//  The colour you see is NOT painted in the Canvas. Instead:
//    1. A `Rectangle().fill(.linearGradient(...))` provides the
//       beautiful pink/purple/yellow colour at full opacity.
//    2. The Canvas (with blur+threshold) is used as a `.mask { }`
//       on that gradient.
//    3. The Canvas itself draws plain WHITE shapes; only its alpha
//       channel matters because it's only being used as a mask.
//
//  This separates "what shape" (Canvas) from "what colour"
//  (gradient), letting you swap colour schemes by changing one
//  line.
//
//  Why `TimelineView(.animation(minimumInterval: 6.6))` for clubbed
//  ────────────────────────────────────────────────────────────────
//  Each tick of the timeline forces SwiftUI to re-render the
//  Canvas, which re-evaluates the random `offset` values per
//  rectangle (gated by `startClubAnimation`). 6.6 seconds is
//  intentionally LONGER than the per-rect 10s `.animation(...)`
//  duration — that way each rectangle has plenty of time to drift
//  toward its target before the next random retarget fires.
//
//  Why `context.resolveSymbol(id:)` + `symbols { ... }`
//  ────────────────────────────────────────────────────
//  `Canvas { ... } symbols: { ... }` lets you embed real SwiftUI
//  views (with `.tag(id)`) inside a Canvas. Inside the drawing
//  block, `resolveSymbol(id:)` retrieves them as `GraphicsContext`-
//  drawable images. This gives the rectangles their cornerRadius,
//  fill, animations, etc — things you couldn't easily reproduce in
//  raw Canvas drawing.
//
//  Key APIs
//  ────────
//  • `Canvas { context, size in ... } symbols: { ... }` — embed
//    SwiftUI views as drawable symbols.
//  • `GraphicsContext.addFilter(.alphaThreshold + .blur)` — the
//    pure-Canvas metaball recipe.
//  • `TimelineView(.animation(minimumInterval:))` — periodic
//    re-render trigger.
//  • `.mask { Canvas { ... } }` — separate colour from shape.
//
//  How to apply
//  ────────────
//  Reach for this pattern when iOS 17 support is required (no
//  custom Metal shaders). For iOS 18+, see
//  `[[MetaballAnimation_iOS26]]` — the shader version is more
//  performant and gives finer control.
//
//  See also
//  ────────
//  • MetaballAnimation_iOS26.swift — Metal-shader version.
//  • AlphaThreshold.metal — the shader the iOS 26 version uses.
//  • View/TextEffectView/MorphingSymbolView.swift — same
//    Canvas+filter recipe applied to SF Symbol morphing.
//

import SwiftUI

struct MetaballAnimationDemoView: View {
    var body: some View {
        MetaballAnimationView()
            .preferredColorScheme(.dark)
    }
}

struct MetaballAnimationView: View {
    /// View Properties
    @State private var dragOffset: CGSize = .zero
    @State private var startClubAnimation: Bool = false
    @State private var type: String = "Single"
    var body: some View {
        VStack {
            Text("Metaball Animation")
                .font(.title)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(15)

            Picker(selection: $type) {
                Text("Metaball")
                    .tag("Single")
                Text("Clubbed")
                    .tag("Clubbed")
            } label: {}
                .pickerStyle(.segmented)

            if type == "Single" {
                singleMetaBall()
            } else {
                clubbedView()
            }
        }
    }

    func clubbedView() -> some View {
        Rectangle()
            .fill(
                .linearGradient(
                    colors: [.red, .pink, .purple],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .mask {
                TimelineView(.animation(minimumInterval: 6.6, paused: false)) { _ in
                    Canvas { context, size in
                        context.addFilter(.alphaThreshold(min: 0.5, color: .white))
                        /// blur radius used to determines the amount of elasticity between 2 elements
                        context.addFilter(.blur(radius: 30))

                        context.drawLayer { ctx in
                            for index in 1 ... 15 {
                                if let resolvedView = context.resolveSymbol(id: index) {
                                    ctx.draw(resolvedView,
                                             at: CGPoint(x: size.width / 2, y: size.height / 2))
                                }
                            }
                        }
                    } symbols: {
                        ForEach(1 ... 15, id: \.self) { index in
                            /// Generate custom offset each time to have view show up at random place
                            /// and clubbed with each other
                            let offset = (startClubAnimation ? CGSize(
                                width: .random(in: -180 ... 180),
                                height: .random(in: -240 ... 240)
                            ) : .zero
                            )

                            clubbedRoundedRectangle(offset: offset)
                                .tag(index)
                        }
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                startClubAnimation.toggle()
            }
    }

    func clubbedRoundedRectangle(offset: CGSize) -> some View {
        RoundedRectangle(cornerRadius: 30, style: .continuous)
            .fill(.white)
            .frame(width: 120, height: 120)
            .offset(offset)
            /// animation duration should less than timeline refresh rate, at line53
            .animation(.easeInOut(duration: 10), value: offset)
    }

    @ViewBuilder
    func singleMetaBall() -> some View {
        Rectangle()
            .fill(
                .linearGradient(
                    colors: [.orange, .yellow, .brown],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .mask {
                Canvas { context, size in
                    context.addFilter(.alphaThreshold(min: 0.5, color: .orange))
                    /// blur radius used to determines the amount of elasticity between 2 elements
                    context.addFilter(.blur(radius: 35))

                    context.drawLayer { ctx in
                        for index in [1, 2] {
                            if let resolvedView = context.resolveSymbol(id: index) {
                                ctx.draw(resolvedView,
                                         at: CGPoint(x: size.width / 2, y: size.height / 2))
                            }
                        }
                    }
                } symbols: {
                    ball()
                        .tag(1)

                    ball(offset: dragOffset)
                        .tag(2)
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation
                    }.onEnded { _ in
                        withAnimation(.interactiveSpring(response: 0.6, dampingFraction: 0.7, blendDuration: 0.7)) {
                            dragOffset = .zero
                        }
                    }
            )
    }

    func ball(offset: CGSize = .zero) -> some View {
        Circle()
            .fill(.white)
            .frame(width: 150, height: 150)
            .offset(offset)
    }
}

#Preview {
    MetaballAnimationDemoView()
}
