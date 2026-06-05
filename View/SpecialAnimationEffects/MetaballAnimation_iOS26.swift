//
//  MetaballAnimation_iOS26.swift
//  animation
//
//  "Metaball" / gooey morph between two SwiftUI views (here, two SF Symbols).
//  The shapes appear to melt into a single blob and re-form as the new symbol
//  — the same trick used for liquid loaders and the iOS dock icon merging.
//
//  When to use this:
//  - Cross-fading two views feels too plain and you want a tactile, organic
//    transition between them (icons, badges, status indicators).
//  - You're swapping content of similar silhouette where a hard cut would
//    flicker. The blur+threshold pipeline hides the discontinuity.
//
//  How the effect works (a recipe worth memorizing):
//    1. Stack the "from" and "to" views and cross-fade their opacities with a
//       standard SwiftUI transition.
//    2. Wrap the stack in a `compositingGroup()` so the blur is applied to
//       the *combined* alpha channel, not each view separately. Without this
//       the two layers blur in isolation and never merge.
//    3. Apply a `.blur(radius:)` driven by an animatable progress. Blur
//       softens both alpha channels into overlapping gradients.
//    4. Pass the blurred result through the `alphaThreshold` Metal shader
//       (see AlphaThreshold.metal). The shader keeps only pixels above an
//       alpha cutoff and snaps them back to full opacity, producing the
//       crisp gooey edge where the two blurs overlap.
//
//  Knobs:
//  - `blurRadius` — bigger = blobbier and slower-feeling; too large and the
//    threshold eats the whole shape mid-transition. ~30–50 works for icons.
//  - The spring on `toggle` controls the morph timing; `bounce: 0` keeps the
//    motion smooth (a bouncy spring makes the threshold "pop").
//
//  iOS 26 note: `@Animatable` macro + `@AnimatableIgnored` is the modern
//  replacement for manually conforming to `Animatable` and writing
//  `animatableData`. Mark only the values that should drive interpolation
//  (`progress`); constants like `blurRadius` are ignored so the compiler
//  doesn't generate needless lerp code.

import SwiftUI

/// Demo host: tap a symbol in the grid to morph the large icon into it.
/// `toggle` flips between `from`/`to` slots so consecutive taps always
/// have a stable "previous" view to morph out of.
struct MetaballMorpthingAnimationDemoView: View {
    @State private var toggle: Bool = false
    @State private var currentSymbolImage: String = "pawprint.fill"
    @State private var nextSymbolImage: String = "pawprint.fill"
    var body: some View {
        MetaballMorpthingView(blurRadius: 40, toggle: toggle) {
            Image(systemName: currentSymbolImage)
                .font(.system(size: 100))

        } to: {
            Image(systemName: nextSymbolImage)
                .font(.system(size: 100))
        }
        .frame(height: 150)
        .frame(maxWidth: .infinity)

        LazyVGrid(columns: Array(repeating: GridItem(), count: 4)) {
            ForEach(demoSymbols, id: \.self) { symbol in
                Button {
                    withAnimation(.iSpring(duration: 0.68)) {
                        if !toggle {
                            nextSymbolImage = symbol
                        } else {
                            currentSymbolImage = symbol
                        }
                        toggle.toggle()
                    }
                } label: {
                    Image(systemName: symbol)
                        .font(.title3)
                        .frame(height: 45)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .background(.fill, in: .rect(cornerRadius: 10))
                        .contentShape(.rect)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(15)
    }

    private var demoSymbols: [String] {
        ["suit.heart.fill", "gamecontroller.fill", "bubble.left.and.bubble.right.fill", "person.2.fill", "video.fill", "moon.fill", "location.fill", "bookmark.fill", "cloud.fill", "flame.fill"]
    }
}

/// Reusable container that morphs between any two views.
/// Usage:
///     MetaballMorpthingView(blurRadius: 40, toggle: isOn) {
///         Image(systemName: "sun.max.fill")
///     } to: {
///         Image(systemName: "moon.fill")
///     }
/// Drive `toggle` inside a `withAnimation { ... }` block — the modifier's
/// `progress` is what's actually animated.
struct MetaballMorpthingView<From: View, To: View>: View {
    var blurRadius: CGFloat
    var toggle: Bool
    @ViewBuilder var from: From
    @ViewBuilder var to: To
    /// View Properties
    @State private var dragOffset: CGSize = .zero

    var body: some View {
        ZStack {
            if !toggle {
                from
                    .contentTransition(.identity)
                    .transition(.opacity)
            }

            if toggle {
                to.contentTransition(.identity)
                    .transition(.opacity)
            }
        }
        .modifier(
            MorphingModifier(
                progress: toggle ? 1 : 0,
                blurRadius: blurRadius
            )
        )
    }
}

@Animatable
private struct MorphingModifier: ViewModifier {
    var progress: CGFloat
    @AnimatableIgnored var blurRadius: CGFloat
    func body(content: Content) -> some View {
        content
            .compositingGroup()
            .blur(radius: blurProgress * blurRadius)
            .visualEffect {
                content,
                    proxy in
                content
                    .layerEffect(
                        ShaderLibrary.alphaThreshold(),
                        maxSampleOffset: proxy.size
                    )
            }
    }

    /// Triangle wave on `progress`: 0 → 0.5 → 0 across a 0…1 transition.
    /// Why: blur should peak at the *midpoint* of the morph (when the two
    /// views are blending) and return to zero at both ends so the start
    /// and end frames are crisp. A linear ramp would leave the destination
    /// view permanently blurred.
    private var blurProgress: CGFloat {
        progress > 0.5 ? abs(1.0 - progress) : progress
    }
}

#Preview {
    MetaballMorpthingAnimationDemoView()
}
