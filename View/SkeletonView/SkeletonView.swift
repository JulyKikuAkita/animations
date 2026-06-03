//
//  SkeletonView.swift
//  animation
//
//  Learning point
//  ──────────────
//  Reusable shimmer-style "skeleton" loading placeholder: a coloured
//  shape (the bone) with a soft, slightly-rotated bright bar that
//  sweeps across it forever, simulating a gradient sheen on brushed
//  metal.
//
//  The four ingredients of the sheen
//  ─────────────────────────────────
//    1. **A wide, blurred rectangle** — `skeletonWidth = size.width / 3`,
//       `blurRadius = max(skeletonWidth / 2, 30)`. Soft gaussian blur is
//       what turns a hard rectangle into a believable highlight.
//    2. **Slight rotation** — 5° gives the diagonal sweep look (pure
//       horizontal feels mechanical).
//    3. **Movement offset animation** — `offset(x: maxX | minX)` toggled
//       inside `withAnimation(.repeatForever)`. The min/max include
//       `+ blurDiameter` so the blurred edges fully clear the shape
//       before restarting (no visible jump).
//    4. **`.blendMode(.luminosity)`** — composites the highlight against
//       the underlying fill instead of just being a paler rectangle.
//       Try `.softLight`, `.overlay`, `.plusLighter` for variations.
//
//  Why the `.transaction` modifier matters
//  ───────────────────────────────────────
//  This is the load-bearing line at the bottom of `body`:
//
//      .transaction { if $0.animation != animation { $0.animation = .none } }
//
//  Without it: any caller-side `withAnimation(.smooth) { ... }` (e.g.
//  the parent toggling layout) would HIJACK the skeleton's repeating
//  animation, making the sheen lurch or freeze. The transaction filter
//  rejects every animation that isn't OUR `repeatForever` one, so the
//  shimmer keeps its own clock.
//
//  Why `compositingGroup()` before `clipShape`
//  ───────────────────────────────────────────
//  Without `compositingGroup`, the blend mode would composite against
//  whatever's behind the skeleton on the screen — including parent
//  backgrounds. With it, the fill+sheen are flattened into a single
//  layer first, so the blend stays self-contained.
//
//  Key APIs
//  ────────
//  • `Shape` generic parameter — caller picks the bone's shape
//    (`.rect`, `.circle`, `.capsule`, custom).
//  • `repeatForever(autoreverses: false)` — one-direction loop.
//  • `.blendMode(.luminosity)` — luminosity-only compositing.
//  • `.transaction { ... }` — local-only animation override.
//
//  How to apply
//  ────────────
//  Drop in any cell that's waiting on data:
//      `SkeletonView(.rect(cornerRadius: 5))`
//      `SkeletonView(.circle)`
//  See `[[SkeletonViewModifier]]` for the redacted-aware companion that
//  applies the same shimmer to a real view via `.skeleton(isRedacted:)`.
//
//  See also
//  ────────
//  • SkeletonView+RedacttDemo.swift — call site showing card layouts
//    that swap shimmer for real content.
//  • SkeletonViewModifier.swift — `.skeleton(isRedacted:)` modifier
//    that runs over a redacted real view (no separate shape).
//
import SwiftUI

struct SkeletonView<S: Shape>: View {
    var shape: S
    var color: Color
    init(_ shape: S, _ color: Color = .gray.opacity(0.3)) {
        self.shape = shape
        self.color = color
    }

    ///
    @State private var isAnimating: Bool = false
    var body: some View {
        shape
            .fill(color)
            /// skeleton effect
            .overlay {
                GeometryReader {
                    let size = $0.size
                    let skeletonWidth = size.width / 3
                    let blurRadius = max(skeletonWidth / 2, 30)
                    let blurDiameter = blurRadius * 2
                    /// Movement Offsets
                    let minX = -(skeletonWidth + blurDiameter)
                    let maxX = size.width + skeletonWidth + blurDiameter

                    // Tip: the inner `frame(height: size.height * 2)` is
                    // a layout trick — give the rectangle 2x the parent's
                    // height so that after the 5° rotation, the rectangle
                    // still covers the full vertical span of the bone
                    // (rotation around centre would otherwise expose
                    // empty corners). The outer `frame(height: size.height)`
                    // re-clips the layout reservation back to the bone size.
                    Rectangle()
                        .fill(.gray)
                        .frame(width: skeletonWidth, height: size.height * 2)
                        .frame(height: size.height)
                        .blur(radius: blurRadius)
                        .rotationEffect(.init(degrees: rotation))
                        .blendMode(.luminosity) // try softSpotlight effect
                        /// repeating moving animation from left to right
                        .offset(x: isAnimating ? maxX : minX)
                }
            }
            .clipShape(shape)
            .compositingGroup()
            .onAppear {
                guard !isAnimating else { return }
                withAnimation(animation) {
                    isAnimating = true
                }
            }
            .onDisappear {
                isAnimating = false
            }
            // Tip: the load-bearing transaction filter.
            // Any caller-side `withAnimation` (e.g. the parent flipping
            // a layout flag) propagates a `Transaction` through the view
            // tree and will OVERRIDE this view's repeating animation
            // mid-flight, breaking the shimmer. Filtering out anything
            // that's not OUR repeating animation keeps the loop intact.
            .transaction {
                if $0.animation != animation {
                    $0.animation = .none
                }
            }
    }

    /// Customized View  Properties
    var rotation: Double {
        5
    }

    var animation: Animation {
        .easeInOut(duration: 1.5).repeatForever(autoreverses: false)
    }
}

/// testing if this animation interferes with the skeleton animation
#Preview {
    @Previewable
    @State var isTapped = false

    SkeletonView(.circle)
        .frame(width: 100, height: 100)
        .onTapGesture { /// introduce a different animation
            withAnimation(.smooth) {
                isTapped.toggle()
            }
        }
        .padding(.bottom, isTapped ? 15 : 0)
}
