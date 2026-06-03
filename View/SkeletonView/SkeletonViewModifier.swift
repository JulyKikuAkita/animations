//
//  SkeletonView.swift
//  animation
//
//  Learning point
//  ──────────────
//  The **redacted-modifier** flavour of skeleton loading: a single
//  `.skeleton(isRedacted:)` modifier wraps any existing real view and,
//  while `isRedacted` is true:
//    1. Applies `.redacted(reason: .placeholder)` so the system replaces
//       text/images with grey bars/blocks.
//    2. Overlays a moving shimmer that's **masked by the redacted
//       version of the same content** — so the sheen lights up only
//       where placeholder bars are, not over the whole rectangle.
//
//  Compare with `[[SkeletonView]]` in the same folder, which takes the
//  opposite approach (substitute a separate `Shape` per leaf). Both
//  ship together so callers can pick whichever suits the use case.
//
//  The mask trick is the load-bearing idea
//  ───────────────────────────────────────
//  Without `.mask { content.redacted(.placeholder) }`, the shimmer
//  would sweep across the entire bounding box — including padding
//  and gaps between bars. By masking with the redacted content
//  itself, the sheen is clipped to *exactly* the shape of the
//  placeholder bars. Looks much more polished.
//
//  Why `.blendMode(.softLight)` here vs `.luminosity` in SkeletonView?
//  ──────────────────────────────────────────────────────────────────
//  `.luminosity` (used in `[[SkeletonView]]`) replaces the underlying
//  hue with the highlight's brightness — fine when the bone is a
//  solid grey rectangle. `.softLight` (this file) gently brightens
//  whatever's underneath, which works better here because the
//  redacted bars already have the system's chosen placeholder colour.
//
//  Same `.transaction { ... }` filter as in SkeletonView
//  ─────────────────────────────────────────────────────
//  The bottom of the modifier filters out any animation that isn't OUR
//  repeating sheen — preventing parent-side `withAnimation { ... }`
//  calls from hijacking and stalling the shimmer mid-sweep.
//
//  Key APIs
//  ────────
//  • `.redacted(reason: .placeholder)` — system-rendered placeholder
//    bars for `Text`, `Image`, etc.
//  • `.mask { ... }` — clip the shimmer to the placeholder silhouette.
//  • `.blendMode(.softLight)` — brighten-only compositing.
//  • `.task { ... }` — start the sheen loop on appear (replaces the
//    older `.onAppear` for async or one-shot setup).
//  • `.transaction { ... }` — same animation isolation trick as
//    `[[SkeletonView]]`.
//
//  How to apply
//  ────────────
//  Drop `.skeleton(isRedacted: isLoading)` on any complex existing
//  view (a Card, a profile row, a search result). Useful when you'd
//  rather not duplicate layout in two states. For per-leaf control
//  over placeholder shape, prefer `[[SkeletonView]]` substitution.
//
//  See also
//  ────────
//  • SkeletonView.swift — shape-substitution alternative.
//  • SkeletonView+RedacttDemo.swift — call-site demo for both.
//
import SwiftUI

extension View {
    func skeleton(isRedacted: Bool) -> some View {
        modifier(SkeletonViewModifier(isRedacted: isRedacted))
    }
}

struct SkeletonViewModifier: ViewModifier {
    var isRedacted: Bool = false
    @State private var isAnimating: Bool = false
    @Environment(\.colorScheme) private var scheme
    func body(content: Content) -> some View {
        content
            .redacted(reason: isRedacted ? .placeholder : [])
            /// Skeleton effect
            .overlay {
                if isRedacted {
                    GeometryReader {
                        let size = $0.size
                        let skeletonWidth = size.width / 3
                        let blurRadius = max(skeletonWidth / 2, 30)
                        let blurDiameter = blurRadius * 2
                        /// Movement Offsets
                        let minX = -(skeletonWidth + blurDiameter)
                        let maxX = size.width + skeletonWidth + blurDiameter

                        Rectangle()
                            .fill(scheme == .dark ? .white : .black)
                            .frame(width: skeletonWidth, height: size.height * 2)
                            .frame(height: size.height)
                            .blur(radius: blurRadius)
                            .rotationEffect(.init(degrees: rotation))
                            /// repeating moving animation from left to right
                            .offset(x: isAnimating ? maxX : minX)
                    }
                    // Tip: mask the shimmer with the REDACTED content,
                    // not the original content. Without `.placeholder`
                    // here, the mask would be the real text/image shapes
                    // — causing the sheen to highlight the actual content
                    // through the redaction. Using the redacted version
                    // makes the sheen visible only on placeholder bars.
                    .mask {
                        content
                            .redacted(reason: .placeholder)
                    }
                    .blendMode(.softLight)
                    .task {
                        guard !isAnimating else { return }
                        withAnimation(animation) {
                            isAnimating = true
                        }
                    }
                    .onDisappear {
                        isAnimating = false
                    }
                    .transaction {
                        if $0.animation != animation {
                            $0.animation = .none
                        }
                    }
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

#Preview {
    @Previewable @State var showSkeleton = true
    CardPlacerHolderView(
        card: Card(
            image: "fox",
            title: "Redacted Demo Card",
            subTitle: "From June 9th 2025"
        )
    )
    .padding(10)
    .skeleton(isRedacted: showSkeleton)
    .onTapGesture {
        showSkeleton.toggle()
    }
}
