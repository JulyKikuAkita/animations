//
//  RippleTransitionDemoView.swift
//  animation
//
//  Created by IFang Lee on 2/22/25.
//
//  Learning point
//  ──────────────
//  Demo for two custom Metal-shader-driven transitions
//  (`.ripple(location:)` and `.reverseRipple(location:)`) defined
//  elsewhere in the project. The ripple effect emits a circular
//  wave from the user's TAP POINT — instead of a centered or
//  edge-anchored transition, the wave spreads from exactly where
//  the user touched. Used by Apple Watch's app-launch animation
//  and many "fluid" iOS reveal effects.
//
//  Two interaction patterns
//  ────────────────────────
//    1. **Tap-to-cycle inside a frame** — tap anywhere on the
//       150×450 image. The tap location is captured in a NAMED
//       coordinate space (`"RIPPLEVIEW"`) so the ripple's origin
//       matches the tap pixel exactly. `count = (count + 1) % 2`
//       cycles between two images with `.transition(.ripple(...))`.
//    2. **Tap a button to reveal a fullscreen overlay** — the
//       button's GLOBAL frame midpoint is captured via
//       `GeometryReader`, then `overlayRippleLocation = (frame.midX,
//       frame.midY)` so the ripple emerges from the BUTTON's
//       centre. The reverse-ripple plays during dismissal,
//       inverting back to the same point.
//
//  Why a NAMED coordinate space for the image
//  ──────────────────────────────────────────
//      .coordinateSpace(.named("RIPPLEVIEW"))
//      .onTapGesture(coordinateSpace: .named("RIPPLEVIEW")) { ... }
//
//  Without a named space, `value.location` from the tap gesture
//  would be in the gesture's host coordinate system, which may
//  include parent paddings / nav bar / safe area. Naming the
//  coordinate space pins the location to (0, 0) of the image
//  view — exactly what the shader expects for `location:` so the
//  ripple emerges from the right pixel.
//
//  Why GLOBAL frame for the button
//  ───────────────────────────────
//  The fullscreen overlay sits at window-coordinate-space, so we
//  need the button's position in window/global coords (not local
//  to the parent VStack). `GeometryReader` + `frame(in: .global)`
//  gives us that.
//
//  Why `.linear(duration: 1)` (not spring)
//  ───────────────────────────────────────
//  Ripple transitions are wave-propagation animations — physically
//  they should spread at constant speed (linear), not bounce.
//  Using `.bouncy` here would make the wave overshoot and look
//  like a rubber band, breaking the "ripple" metaphor.
//
//  Key APIs
//  ────────
//  • `.transition(.ripple(location:))` — project-local Metal
//    shader transition. Implementation in
//    `[[ProjectExtensions/RippleTransition]]` (or similar).
//  • `.coordinateSpace(name:)` + `.onTapGesture(count:coordinateSpace:)` —
//    pinned-coordinate tap.
//  • `GeometryReader { $0.frame(in: .global) }` — read button's
//    screen position.
//  • `.transition(.reverseRipple(...))` — sister transition that
//    plays backward (collapses to the point).
//
//  How to apply
//  ────────────
//  Use whenever a transition should feel ANCHORED to the user's
//  point of interaction: tap-to-launch buttons, share menus
//  emerging from share buttons, light/dark mode toggles. Same
//  shader recipe powers iOS's accessibility "magnify on tap"
//  visual.
//
//  See also
//  ────────
//  • TransitionAnimationIOS26.swift — sibling shared-element
//    transition without shader (pure layout interpolation).
//  • View/Card/CardScrollView.swift — uses
//    `matchedTransitionSource` + `.zoom` for paired enter/exit.
//

import SwiftUI

struct RippleTransitionDemoView: View {
    let imageNames = ["AI_grn", "AI_pink"]
    @State private var count: Int = 0
    @State private var rippleLocation: CGPoint = .zero
    @State private var showOverlayView: Bool = false
    @State private var overlayRippleLocation: CGPoint = .zero

    var body: some View {
        NavigationStack {
            VStack {
                GeometryReader {
                    let size = $0.size

                    ForEach(0 ..< imageNames.count, id: \.self) { index in
                        if count == index {
                            imageView(index, size: size)
                                .transition(.ripple(location: rippleLocation))
                        }
                    }
                }
                .frame(width: 350, height: 450)
                .coordinateSpace(.named("RIPPLEVIEW"))
                .onTapGesture(count: 1, coordinateSpace: .named("RIPPLEVIEW")) { location in
                    rippleLocation = location
                    withAnimation(.linear(duration: 1)) {
                        count = (count + 1) % 2
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .bottomTrailing) {
                GeometryReader {
                    let frame = $0.frame(in: .global)

                    Button {
                        overlayRippleLocation = .init(x: frame.midX, y: frame.midY)
                        withAnimation(.linear(duration: 1)) {
                            showOverlayView = true
                        }

                    } label: {
                        Image(systemName: "square.and.arrow.up.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .frame(width: 50, height: 50)
                            .background(.indigo.gradient, in: .circle)
                            .clipShape(.rect)
                    }
                }
                .frame(width: 50, height: 50)
                .padding(15)
            }
            .navigationTitle("Ripple Transition")
        }
        .overlay {
            if showOverlayView {
                ZStack {
                    Rectangle()
                        .fill(.indigo.gradient)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.55)) {
                                showOverlayView = false
                            }
                        }

                    Text("Tap anywhere to dismiss!")
                }
                .transition(.reverseRipple(location: overlayRippleLocation))
            }
        }
    }

    private func imageView(_ index: Int, size: CGSize) -> some View {
        Image(imageNames[index])
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: size.width, height: size.height)
            .clipShape(.rect(cornerRadius: 30))
    }
}

#Preview {
    RippleTransitionDemoView()
}
