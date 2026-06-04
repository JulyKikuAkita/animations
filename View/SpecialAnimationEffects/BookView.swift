//
//  BookView.swift
//  animation
//
//  Learning point
//  ──────────────
//  Interactive "openable book" / profile card with a 3D page-flip
//  animation. Tapping flips the front cover open along its left
//  spine, revealing left/right "inside" pages — like opening a
//  hardcover book in app form. Used for profile cards, story
//  reveals, photo-album entries.
//
//  Three reusable mechanics
//  ────────────────────────
//    1. **`Animatable` ViewModifier with `progress` as `animatableData`** —
//       on its own, `withAnimation { progress = 1 }` would jump the
//       value step-by-step. Conforming `OpenableBookView` to
//       `Animatable` and exposing `progress` lets SwiftUI interpolate
//       it at frame rate so the 3D rotation, shadow, and offset all
//       update smoothly together.
//    2. **`rotation3DEffect(anchor: .leading, perspective: 0.3)`** —
//       the front cover rotates around its leading edge (the spine)
//       with mild perspective. Setting `perspective: 0.3` (not 1.0)
//       reduces the foreshortening "stretch" that distorts cover
//       images at large angles.
//    3. **Mid-flip content swap (>90° = back face visible)** — past
//       90° rotation we'd be looking at the *back* of the cover.
//       At that point we overlay `insideLeft` flipped horizontally
//       (`scaleEffect(x: -1)`) so the user sees the inside-left
//       content as if reading. Same trick as the flip-clock digits.
//
//  Why offset by `(width / 2) * progress`
//  ──────────────────────────────────────
//  When fully open, the book occupies twice its closed width (the
//  inside pages take up the second column). Without the offset, the
//  open book would slide left of its closed position. Shifting the
//  whole thing right by half-width as it opens keeps the visual
//  centre stable.
//
//  Shadow during flip
//  ──────────────────
//  Two `.shadow(color: shadowColor.opacity(...) ...)` calls —
//  one on the inside-right page (gradually appears as `progress`
//  grows) and a constant one on the front cover. Combined, they
//  give the book a sense of depth as the cover opens.
//
//  Key APIs
//  ────────
//  • `Animatable` + `animatableData` on a generic ViewModifier —
//    canonical pattern for interpolating multi-property animations.
//  • `rotation3DEffect(.init(degrees:), axis:, anchor:, perspective:)` —
//    Y-axis rotation around the spine.
//  • `UnevenRoundedRectangle` — rounded only on the trailing edges
//    (where the open book exposes them).
//
//  How to apply
//  ────────────
//  Use whenever a card needs a "reveal more" interaction with
//  physical-feeling motion (about/profile cards, story chapters,
//  recipe books, foldable cards). The `Animatable progress` pattern
//  generalises to any multi-property morph driven by one value.
//
//  See also
//  ────────
//  • View/TextEffectView/FlipClockTextEffectView.swift — same
//    rotation-past-90°-swap-content trick on a single digit.
//  • View/Card/* — non-rotating reveal patterns for comparison.
//

import SwiftUI

struct BookView: View {
    /// View properties
    @State private var progress: CGFloat = 0
    var profile: Profile
    var body: some View {
        VStack {
            OpenableBookView(config: .init(progress: progress)) { size in
                frontView(size, profile.profilePicture)
            } insideLeft: { _ in
                leftView()
            } insideRight: { _ in
                rightView()
            }
            .onTapGesture {
                withAnimation(.snappy(duration: 1.0)) {
                    progress = (progress == 1.0 ? 0.2 : 1.0)
                }
            }

            ////            VStack { /// debug slider
            ////                Slider(value: $progress)
            ////                Button("Toggle") {
            ////                    withAnimation(.snappy(duration: 1.0)) {
            ////                       /// progress need to be animatable data
            /// otherwise the value jumping from 0 to 1 directly instead of progressing to 1
            ////                        progress = ( progress == 1.0 ? 0.2 : 1.0)
            ////                    }
            ////                }
            ////                .buttonStyle(.borderedProminent)
            ////            }
            ////            .padding()
            ////            .background(.background, in: .rect(cornerRadius: 10))
            ////            .padding(.top, 50)
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.gray.opacity(0.15))
    }

    func frontView(_ size: CGSize, _ coverImage: String) -> some View {
        Image(coverImage)
            .resizable()
            .aspectRatio(contentMode: .fill)
//            .offset(y: 10)
            .frame(width: size.width, height: size.height)
    }

    func leftView() -> some View {
        VStack(spacing: 5) {
            Image("fox")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 100, height: 100)
                .clipShape(.circle)
                .shadow(color: .black.opacity(0.15), radius: 5, x: 5, y: 5)

            Text(profile.username)
                .fontWidth(.condensed)
                .fontWeight(.bold)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }

    func rightView() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(.system(size: 14))

            // swiftlint:disable:next line_length
            Text("Nanachi is a shiba inu with amazing mellow temperament which is not known for this breed. He might be a far relative from fox but he have never met one in his life.")
                .font(.caption)
                .foregroundStyle(.gray)
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }
}

/// Interactive Book Card View
struct OpenableBookView<Front: View, InsideLeft: View, InsideRight: View>: View, Animatable {
    var config: Config = .init()
    @ViewBuilder var front: (CGSize) -> Front
    @ViewBuilder var insideLeft: (CGSize) -> InsideLeft
    @ViewBuilder var insideRight: (CGSize) -> InsideRight

    var animatableData: CGFloat {
        get { config.progress }
        set { config.progress = newValue }
    }

    var body: some View {
        GeometryReader {
            let size = $0.size

            /// limiting progress between 1 and 0
            let progress = max(min(config.progress, 1), 0)
            let rotation = progress * -180
            let cornerRadius = config.cornerRadius
            let shadowColor = config.shadowColor

            ZStack {
                insideRight(size)
                    .frame(width: size.width, height: size.height)
                    .clipShape(.rect(
                        topLeadingRadius: 0,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: cornerRadius,
                        topTrailingRadius: cornerRadius
                    ))
                    .shadow(color: shadowColor.opacity(0.1 * progress), radius: 5, x: 5, y: 0)
                    .overlay(alignment: .leading) { // adding a divider between left and right view
                        Rectangle()
                            .fill(config.dividerBackground.shadow(.inner(color: shadowColor.opacity(0.15), radius: 2)))
                            .frame(width: 6)
                            .offset(x: -3)
                            .clipped()
                    }

                front(size)
                    .frame(width: size.width, height: size.height)
                    /// disable interaction once it's flipped
                    .allowsTightening(-rotation < 90)
                    // Tip: the 90° back-face content swap.
                    // Rotating past 90° we'd be seeing the cover's REAR
                    // (mirror-flipped). Overlay `insideLeft` here and
                    // counter-mirror it (`scaleEffect(x: -1)`) so the
                    // user reads it correctly. `.transition(.identity)`
                    // ensures a hard cut at exactly 90° instead of a
                    // crossfade through both layers.
                    .overlay {
                        if -rotation > 90 {
                            insideLeft(size)
                                .frame(width: size.width, height: size.height)
                                .scaleEffect(x: -1)
                                .transition(.identity)
                        }
                    }
                    .clipShape(.rect(
                        topLeadingRadius: 0,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: cornerRadius,
                        topTrailingRadius: cornerRadius
                    ))
                    .shadow(color: shadowColor.opacity(0.1), radius: 5, x: 5, y: 0)
                    .rotation3DEffect(
                        .init(degrees: rotation),
                        axis: (x: 0.0, y: 1.0, z: 0.0),
                        anchor: .leading,
                        perspective: 0.3 // avoid stretching image
                    )
            }
            .offset(x: (config.width / 2) * progress) // center the book when opened
        }
        .frame(width: config.width, height: config.height)
    }

    /// Configuration
    struct Config {
        var width: CGFloat = 150
        var height: CGFloat = 200
        var progress: CGFloat = 0
        var cornerRadius: CGFloat = 10
        var dividerBackground: Color = .white
        var shadowColor: Color = .black
    }
}

#Preview {
    BookView(profile: profiles.first!)
}
