//
//  DuoBookFlipDemo.swift
//  animation
//
//  Created on 10/5/26.
//
//  Learning point
//  ──────────────
//  A two-page book that folds its left page over the spine. The front
//  page rotates in 3D around the spine, the back page is revealed
//  underneath, and `[[DuoEdgeBlur]]` blurs the edge while it moves.
//
//  1. Why `@Animatable` modifiers instead of inline modifiers
//  ──────────────────────────────────────────────────────────
//  `withAnimation` does NOT run `body` once per frame. `body` runs ONCE
//  with the final value (e.g. degree = 180), and SwiftUI then
//  interpolates only the `animatableData` of animatable views and
//  modifiers between the old and new values.
//
//  So any non-linear logic written inline in `body` sees only the end
//  value:
//
//      .zIndex(foldAngle.degrees > 90 ? 0 : 1)
//      // body sees 180 → zIndex flips to 0 at the START of the
//      // animation, not when the page crosses 90°.
//
//  Moving the logic into a `ViewModifier` marked `@Animatable` makes
//  `angle` / `progress` its animatableData. SwiftUI then calls the
//  modifier's `body(content:)` every frame with the interpolated
//  value (0, 1.3, 2.7 … 180), so:
//    - `AnimatedZIndex`  flips stacking order exactly at 90°.
//    - `AnimatedOpacity` follows its piecewise curve (fade in over
//      the first half, then hold at 1) instead of a linear fade
//      between the start and end opacity.
//    - `AnimatedRotation` — `rotation3DEffect` already animates on its
//      own; wrapping it just keeps every rotated layer (stroke, fill,
//      masks) on one shared, reusable definition.
//
//  Rule of thumb: if a value goes through `if`, `>`, `max`, or a
//  piecewise formula before reaching a modifier, put that logic in an
//  `@Animatable` modifier.
//  Caveat: shader arguments in `edgeBlur` are not animatableData, so
//  during `withAnimation` the shader receives the final progress
//  straight away. Only the Slider drives it frame-by-frame.
//
//  2. `mask` vs `overlay` — same layout, opposite purpose
//  ──────────────────────────────────────────────────────
//  Both take a view that is laid out in the base view's frame
//  (honoring `alignment`). The difference is what they do with it:
//
//    overlay  → ADDS pixels: draws the view on top of the base.
//    mask     → REMOVES pixels: keeps the base only where the mask
//               view is opaque. Colors are ignored; only alpha counts
//               (opaque = visible, clear = hidden, 50% = half faded).
//    clipShape → a `mask` that only accepts a `Shape`.
//
//  Use overlay to show something extra and mask to hide part of what
//  is already there. In this file:
//    - front `.mask { shape.modifier(AnimatedRotation) }` clips the
//      image to the 3D-ROTATED page silhouette. `clipShape` can't do
//      this because a rotated shape is a View, not a Shape.
//    - back `.mask { Rectangle().modifier(AnimatedOpacity) }` is an
//      alpha mask used as an animated fade-in.
//    - back `.mask(alignment: .trailing) { Rectangle().overlay { … } }`
//      is overlay INSIDE a mask, which builds a UNION of the two alphas:
//      the back page is visible on the right half PLUS wherever the
//      folding page currently covers.
//
//  3. Why `Rectangle()` in some places and `shape` in others
//  ─────────────────────────────────────────────────────────
//  `shape` (UnevenRoundedRectangle) is used wherever the page OUTLINE
//  must be visible or must match exactly: stroke, black fill, and
//  the front page's clip.
//  `Rectangle()` is used where only "a full opaque area" is needed:
//    - root `Rectangle().fill(.clear).aspectRatio(…)`: an invisible
//      layout placeholder. Shapes fill the proposed space, so this
//      reserves a book-sized frame that the overlay then fills.
//      (`Color.clear` would work the same.)
//    - opacity mask: the back is already rounded by `clipShape`, so
//      the mask only needs to carry alpha, and extra corners would
//      cut it again.
//    - right-half mask: must stay square at the spine. Using `shape`
//      would round the spine-side corners and leave notches, and the
//      -1pt leading padding lets it bleed past the spine to hide the
//      seam line.

import SwiftUI

struct DuoBookFlipDemo: View {
    @State private var config: DuoBookConfig = .init(
        aspect: 1.39, strokeWidth: 10, leadingRadius: 5, trailingRadius: 30
    )
    @State private var foldDegree: CGFloat = 0
    var body: some View {
        VStack {
            DuoBookView(config: config, degree: $foldDegree) {
                Image(.nanachiPaint)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } back: {
                Image(.nanachiPaint)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }

            Slider(value: $foldDegree, in: 0 ... 180)
                .padding(50)

            Button("Run Animation") {
                withAnimation(.easeInOut(duration: 2)) {
                    foldDegree = foldDegree == 180 ? 0 : 180
                }
            }
        }
        .padding()
    }
}

struct DuoBookConfig {
    var aspect: CGFloat
    var strokeWidth: CGFloat
    var strokeColor: Color = .primary
    var leadingRadius: CGFloat
    var trailingRadius: CGFloat
}

struct DuoBookView<Front: View, Back: View>: View {
    var config: DuoBookConfig
    @Binding var degree: CGFloat
    @ContentBuilder var front: Front
    @ContentBuilder var back: Back
    var body: some View {
        Rectangle()
            .fill(.clear)
            .aspectRatio(config.aspect, contentMode: .fit)
            .overlay {
                let clampedDegree: CGFloat = degree.clamped(to: 0 ... 180)
                let foldAngle: Angle = .degrees(clampedDegree)
                let foldProgress: CGFloat = (foldAngle.degrees / 180)

                GeometryReader {
                    let size = $0.size
                    let pageWidth = size.width / 2
                    let shape = UnevenRoundedRectangle(
                        topLeadingRadius: config.leadingRadius * (1 - foldProgress),
                        bottomLeadingRadius: config.leadingRadius * (1 - foldProgress),
                        bottomTrailingRadius: config.trailingRadius,
                        topTrailingRadius: config.trailingRadius
                    )

                    ZStack(alignment: .leading) {
                        shape
                            .stroke(config.strokeColor, lineWidth: config.strokeWidth)
                            .frame(width: pageWidth)
                            .frame(maxWidth: .infinity, alignment: .trailing)

                        shape
                            .stroke(config.strokeColor, lineWidth: config.strokeWidth)
                            .frame(width: pageWidth)
                            .modifier(AnimatedRotation(angle: foldAngle))
                            .overlay {
                                ZStack {
                                    shape
                                        .fill(.black)
                                        .modifier(AnimatedRotation(angle: foldAngle))

                                    front
                                        .frame(width: pageWidth, height: size.height)
                                        .edgeBlur(isLeading: false, width: pageWidth, progress: foldProgress)
                                        .clipShape(shape)
                                        .mask {
                                            shape
                                                .modifier(AnimatedRotation(angle: foldAngle))
                                        }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .modifier(AnimatedZIndex(angle: foldAngle))

                        back
                            .frame(width: size.width, height: size.height)
                            .edgeBlur(isLeading: true, width: pageWidth * 1.15, progress: 1 - foldProgress)
                            .clipShape(.rect(cornerRadius: config.trailingRadius))
                            .mask {
                                Rectangle()
                                    .modifier(AnimatedOpacity(progress: foldProgress))
                            }
                            .mask(alignment: .trailing) {
                                // remove any center black line while transitioning animation (> 90 deg)
                                let extraPadding: CGFloat = foldProgress > 0.5 ? -1 : 0

                                // shape
                                Rectangle()
                                    .padding(.leading, extraPadding)
                                    .frame(width: pageWidth)
                                    .overlay(alignment: .leading) {
                                        shape
                                            .frame(width: pageWidth)
                                            .modifier(AnimatedRotation(angle: foldAngle))
                                    }
                            }
                    }
                    .compositingGroup()
                    .offset(x: -(pageWidth / 2) * (1 - foldProgress))
                }
            }
            .padding(config.strokeWidth / 2)
    }
}

@Animatable
private struct AnimatedRotation: ViewModifier {
    var angle: Angle
    func body(content: Content) -> some View {
        content
            .rotation3DEffect(
                -angle,
                axis: (x: 0, y: 1, z: 0),
                anchor: .leading,
                perspective: 0.35
            )
    }
}

@Animatable
private struct AnimatedZIndex: ViewModifier {
    var angle: Angle
    func body(content: Content) -> some View {
        content
            .zIndex(angle.degrees > 90 ? 0 : 1)
    }
}

@Animatable
private struct AnimatedOpacity: ViewModifier {
    var progress: CGFloat

    func body(content: Content) -> some View {
        let opacity = progress > 0.5 ? 1 : progress / 0.5

        content
            .opacity(opacity)
    }
}

private extension View {
    @ContentBuilder
    func edgeBlur(isLeading: Bool, width: CGFloat, progress: CGFloat) -> some View {
        let edgeValue: CGFloat = isLeading ? 0 : 1

        visualEffect { content, proxy in
            content
                .layerEffect(
                    ShaderLibrary.edgeBlur(
                        .float2(proxy.size),
                        .float(edgeValue),
                        .float(width),
                        .float(progress)
                    ),
                    maxSampleOffset: proxy.size
                )
        }
    }
}

#Preview {
    DuoBookFlipDemo()
}
