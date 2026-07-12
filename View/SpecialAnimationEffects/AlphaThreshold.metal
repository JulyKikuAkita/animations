//
//  AlphaThreshold.metal
//  animation
//
//  Created on 5/25/26.
//
//  The "threshold" half of the metaball / gooey morph effect.
//  Pair either shader with a SwiftUI `.blur(radius:)` applied to a
//  `compositingGroup()` — the blur smears alpha into soft gradients, and
//  the shader cuts those gradients back into a shape, fusing any two
//  overlapping views into a single blob with one continuous outline.
//
//  Two variants:
//  - `alphaThreshold`    — hard binary cut. Every pixel ends up fully
//                          opaque or fully transparent, so the blob has a
//                          crisp but aliased (jagged) 1-bit edge.
//  - `alphaV2Threshold`  — soft cut. A `smoothstep` band ramps alpha
//                          across ~1px, anti-aliasing the outline. Prefer
//                          this for small UI that scales/moves (e.g. the
//                          Dynamic Island pull-to-refresh in
//                          List+Extension.swift); use the hard variant when
//                          you want a deliberately pixelated / retro edge.
//
//  When to use:
//  - Gooey transitions between icons / badges (see MetaballMorpthingView).
//  - Liquid loaders where multiple drops should merge as they touch.
//  - Anywhere you want "shapes that flow together" instead of two layered
//    transparencies.
//
//  Why threshold-after-blur works: blurring the alpha channel of two
//  nearby shapes creates a region where their faded edges sum to >= the
//  threshold. The shader treats that combined region as opaque, so the
//  shapes look connected. Pull them apart and the sum drops below the
//  threshold — they snap back into separate shapes. That snap is the
//  metaball look.
//
//  Tuning:
//  - `threshold` (0.5 in both) — raise toward 1.0 for tighter, smaller
//    blobs (shapes merge later, separate sooner). Lower toward 0.0 for
//    puffier, eagerly-merging blobs.
//  - `edge` (v2 only, 0.02) — width of the soft transition band. Larger =
//    fuzzier outline; near 0 approaches the hard `alphaThreshold` look.
//  - The blur radius on the SwiftUI side is the bigger lever; the shader
//    just decides where to cut.
//
//  Note on unpremultiply (`color.rgb / color.a`): SwiftUI delivers
//  premultiplied-alpha pixels. After a blur, alpha is partially
//  attenuated, so dividing by alpha restores the color before re-emitting
//  it — otherwise the blob's interior would look washed out. v1 divides
//  only inside the opaque branch (alpha is safely non-zero there); v2 runs
//  branchless for every pixel, so it clamps the divisor with
//  `max(color.a, 0.001h)` to avoid a divide-by-zero on transparent pixels.

#include <metal_stdlib>
#include <SwiftUI/SwiftUI.h>
using namespace metal;

/// Hard-edged variant: binary opaque/transparent cut at `thresholdValue`.
[[stitchable]] half4 alphaThreshold(float2 position, SwiftUI::Layer layer) {
    float thresholdValue = 0.5;
    half4 color = layer.sample(position);
    return color.a >= thresholdValue ? half4(color.rgb / color.a, 1.0) : half4(0.0);
}

/// Anti-aliased variant: `smoothstep` gives the blob a soft, ~1px outline.
[[stitchable]] half4 alphaV2Threshold(float2 position, SwiftUI::Layer layer) {
    half4 color = layer.sample(position);
    half threshold = 0.5h;
    half edge = 0.02h;
    half alpha = smoothstep(threshold - edge, threshold + edge, color.a);
    return half4(color.rgb / max(color.a, 0.001h), alpha);
}
