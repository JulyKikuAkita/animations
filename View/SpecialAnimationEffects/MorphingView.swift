//
//  MorphingView.swift
//  animation
//
//  Learning point
//  ──────────────
//  Pre-iOS-17 / KeyframeAnimator-free version of the gooey symbol
//  morph effect. Same visual goal as `[[MorphingSymbolView]]` but
//  built on top of a manual `Timer.publish(every: 0.01)` loop +
//  state-machine state.
//
//  Note on the filename
//  ────────────────────
//  Header says "iOS17" but this file works back to iOS 16 — it
//  uses Canvas filters and a Timer publisher, no iOS 17-only APIs.
//  The companion `[[MorphingSymbolView]]` (this folder, the cleaner
//  iOS-17+ version) replaces the timer with a `KeyframeAnimator`.
//
//  How the timer-driven morph works
//  ────────────────────────────────
//  A `Timer.publish(every: 0.01, on: .main, in: .common)` ticks
//  every 10ms. On each tick (only while `animateMorph == true`):
//
//      blurRadius += 0.5
//      if blurRadius == 20  → swap to the picked symbol (mid-morph)
//      if blurRadius == 40  → end animation, reset to 0
//
//  The actual blur applied to the Canvas filter is:
//
//      .blur(radius: blurRadius >= 20 ? 20 - (blurRadius - 20) : blurRadius)
//
//  → a triangle wave: 0 → 20 (peak at midpoint) → 0. Same
//  semantic as the `KeyframeAnimator`'s peak-then-fall in
//  `[[MorphingSymbolView]]`, just unrolled manually.
//
//  Three reusable mechanics
//  ────────────────────────
//    1. **Triangle-wave blur via timer + state-machine** — works on
//       any iOS version, but jittery under load. Reach for this
//       only when `KeyframeAnimator` isn't available.
//    2. **Image-as-mask for content morph** — the foreground
//       `Image("fox")` is masked by the morphing Canvas. Same
//       separation-of-concerns trick as the metaball file:
//       Canvas owns the SHAPE, the Image owns the COLOUR.
//    3. **Toggle to bypass the morph** — the "Turn off Image
//       Morph" toggle replaces the fox image with a teal rectangle
//       inline, demonstrating that the masking pipeline is
//       content-agnostic.
//
//  Why mid-morph symbol swap (`blurRadius == 20`)
//  ──────────────────────────────────────────────
//  Same reason as `[[MorphingSymbolView]]`: when blur is at peak,
//  the underlying symbol is fully obscured by the threshold mask
//  → swapping the symbol at this instant means the user never
//  sees the discrete change. After peak, blur recedes and the
//  NEW symbol resolves out of the goo.
//
//  Why a `Picker` overlay with `.opacity(animateMorph ? 0.05 : 0)`
//  ──────────────────────────────────────────────────────────────
//  The 5% white overlay during animation acts as a soft "press"
//  feedback while the morph plays — and prevents the user from
//  rapidly tapping new symbols mid-animation, which would
//  interrupt the timer state machine.
//
//  Key APIs
//  ────────
//  • `Timer.publish + .autoconnect()` — pre-Async-Algorithms
//    timer driven from a Combine publisher.
//  • `Canvas + addFilter(.alphaThreshold(min: 0.3) + .blur)` —
//    same gooey threshold trick as elsewhere.
//  • `.mask { Canvas { ... } }` — Canvas as silhouette source.
//
//  How to apply
//  ────────────
//  Reach for this when you need iOS 16 support; otherwise prefer
//  `[[MorphingSymbolView]]`. The "swap content at peak blur"
//  trick is the load-bearing concept either way.
//
//  See also
//  ────────
//  • MorphingSymbolView.swift — modern KeyframeAnimator version.
//  • MetaballAnimation_iOS26.swift — Metal-shader alternative.
//  • MetaballAnimationView.swift — sister Canvas demo (multiple
//    blobs, draggable variant).
//

import SwiftUI

struct MorphingDemoView: View {
    var body: some View {
        MorphingView()
            .preferredColorScheme(.dark)
    }
}

struct MorphingView: View {
    /// View Properties
    @State var currentImage: CustomShape = .heart
    @State var pickerImage: CustomShape = .heart

    @State var turnOffImageMorph: Bool = false
    @State var blurRadius: CGFloat = .zero
    @State var animateMorph: Bool = false
    var body: some View {
        VStack {
            /// Achieve  Image morph by mask the Canvas shape with image
            GeometryReader { proxy in
                let size = proxy.size

                Image("fox")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .offset(x: 20, y: -40)
                    .frame(width: size.width, height: size.height)
                    .clipped()
                    .overlay {
                        Rectangle()
                            .fill(.teal)
                            .opacity(turnOffImageMorph ? 1 : 0)
                    }
                    .mask {
                        /// Morphing shapes with the help of canvas and filters
                        Canvas { context, size in
                            context.addFilter(.alphaThreshold(min: 0.3)) /// try different value for morph shape change
                            /// blur plays a major role to achieve morphing effect
                            context.addFilter(
                                .blur(radius: blurRadius >= 20 ? 20 - (blurRadius - 20) : blurRadius)
                            )

                            context.drawLayer { ctx in
                                if let resolvedImage = context.resolveSymbol(id: 1) {
                                    ctx.draw(resolvedImage, at: CGPoint(x: size.width / 2, y: size.height / 2),
                                             anchor: .center)
                                }
                            }
                        } symbols: {
                            ResolvedImage(currentImage: $currentImage)
                                .tag(1)
                        }
                        .onReceive(
                            /// demo using timer, we can use TimelineView too
                            Timer
                                .publish(every: 0.01, on: .main, in: .common)
                                .autoconnect()
                        ) { _ in
                            if animateMorph {
                                if blurRadius <= 40 {
                                    blurRadius += 0.5 /// your desire value for animation speed,

                                    if blurRadius.rounded() == 20 {
                                        /// Update to the next image
                                        currentImage = pickerImage
                                    }
                                }

                                if blurRadius.rounded() == 40 {
                                    /// end animation and reset blur radius to zero
                                    animateMorph = false
                                    blurRadius = 0
                                }
                            }
                        }
                    }
            }
            .frame(height: 350)

            Picker("", selection: $pickerImage) {
                ForEach(CustomShape.allCases, id: \.rawValue) { shape in
                    Image(systemName: shape.rawValue)
                        .tag(shape)
                }
            }
            .pickerStyle(.segmented)
            .overlay {
                Rectangle()
                    .fill(.primary)
                    .opacity(animateMorph ? 0.05 : 0)
            }
            .padding(15)
            .padding(.top, -50)
            .onChange(of: pickerImage) {
                animateMorph = true
            }

            Toggle("Turn off Image Morph", isOn: $turnOffImageMorph)
                .fontWeight(.semibold)
                .padding(.horizontal, 15)
                .padding(.top, 10)
        }
        .offset(y: -50)
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

struct ResolvedImage: View {
    @Binding var currentImage: CustomShape
    var body: some View {
        Image(systemName: currentImage.rawValue)
            .font(.system(size: 200))
            .animation(
                .interactiveSpring(
                    response: 0.7,
                    dampingFraction: 0.8,
                    blendDuration: 0.8
                ),
                value: currentImage
            )
            .frame(width: 300, height: 300)
    }
}

#Preview {
    MorphingDemoView()
}
