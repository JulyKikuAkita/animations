//
//  DuoEdgeBlur.metal
//  animation
//
//  Created on 10/5/26.
//
//  Learning point
//  ──────────────
//  A `layerEffect` that blurs ONE vertical edge of a page, fading to
//  sharp toward the other side. Used by `[[DuoBookFlipDemo]]` so the
//  folding page's moving edge looks motion-blurred.
//
//  Parameters (from Swift)
//    size      layer size in points (`proxy.size`)
//    edge      0 = blur the leading (left) edge, 1 = the trailing edge
//    width     how far in from that edge the blur reaches, in points
//    progress  0…1 overall blur amount (the fold progress)
//
//  1. How strong is the blur at this pixel?
//  ────────────────────────────────────────
//    dist     = distance from the chosen edge
//    falloff  = saturate(1 - dist / width)   → 1 at edge, 0 at `width`
//    strength = pow(falloff, 1.35) * smoothstep(0, 1, progress)
//
//  - `pow(…, 1.35)` bends the linear ramp so the blur drops off faster
//    away from the edge (exponent > 1 = tighter to the edge).
//  - `smoothstep(progress)` is a MULTIPLIER, so progress 0 means
//    strength 0, which leaves the image sharp. Parenthesis placement matters:
//        pow(falloff, 1.35 * smoothstep(progress))   // ✗ wrong
//    puts progress in the exponent, and x⁰ = 1 gives FULL blur at
//    progress 0. Scale an effect by multiplying it; don't feed the
//    scale into the exponent.
//  - `reach` = blur radius in points for this pixel. Below 1pt the
//    result would look identical to the source, so return early and
//    skip the 48-sample loop. Most pixels, and every pixel at
//    progress 0, take this cheap path.
//
//  2. How the blur is sampled — a golden-angle spiral (Vogel disk)
//  ───────────────────────────────────────────────────────────────
//  A box or Gaussian blur samples a grid; this one samples 48 points
//  on a spiral, which gives a smooth, round blur with few samples:
//
//    - Angle: each sample turns by the golden angle (137.5°, the
//      `goldenTurn` rotation matrix). Successive points never line up,
//      so the disk is covered evenly, like sunflower seeds.
//    - Radius: `d = sqrt((i + 0.5) / N)`. The sqrt spreads points evenly
//      by AREA (a ring's area grows with r², so linear radii would
//      crowd the center).
//    - Weight: `exp(-2 d²)` is a Gaussian falloff, so near samples count
//      more and the blur looks soft instead of a flat smear.
//    - `clamp(p, 0.5, size - 0.5)` stops samples from reading outside
//      the layer, where pixels are transparent and would darken
//      the edge.
//    - `sum / total` normalizes, so weights don't have to add to 1.
//
//  3. Why a random start angle per pixel
//  ─────────────────────────────────────
//  With the same spiral at every pixel, 48 samples leave visible
//  ring/streak artifacts (banding). `randomAngle` is interleaved
//  gradient noise, a cheap hash of the pixel position, used to rotate
//  each pixel's spiral differently. That turns banding into fine grain,
//  which the eye reads as smooth blur.
//
//  4. Swift side contract
//  ──────────────────────
//  `maxSampleOffset` in `.layerEffect` must cover the farthest sample
//  (`reach` max = 2 * blurRadius = 80pt). Passing `proxy.size` is
//  generous but safe. If it's too small, SwiftUI cuts off the samples and
//  the blur clips.

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

static float randomAngle(float2 p) {
    return fract(52.9829189 * fract(dot(p, float2(0.06711056, 0.00583715)))) * 2.0 * M_PI_F;
}

[[ stitchable ]] half4 edgeBlur(
  float2 pos, SwiftUI::Layer layer, float2 size,
  float edge, float width, float progress
){
    /// custom properties
    float blurRadius = 40;
    int sampleCount = 48;
    // Angle 137.508
    const float GA = 2.39996323;
    const float2x2 goldenTurn = float2x2(float2(cos(GA), sin(GA)), float2(-sin(GA), cos(GA)));

    float dist = edge < 0.5 ? pos.x : size.x - pos.x;
    float strength = pow(saturate(1.0 - dist / width), 1.35) * smoothstep(0.0, 1.0, progress);
    float reach = 2.0 * blurRadius * strength;
    if (reach < 1.0) return layer.sample(pos);

    float angle = randomAngle(pos);
    float2 dir = float2(cos(angle), sin(angle));

    half4 sum = 0;
    float total = 0;

    for (int i = 0; i < sampleCount; i++) {
        float d = sqrt((float(i) + 0.5) / float(sampleCount));
        float w = exp(-2.0 * d * d);
        float2 p = clamp(pos + dir * d * reach, float2(0.5), size - 0.5);

        sum += layer.sample(p) * half(w);
        total += w;
        dir = goldenTurn * dir;
    }

    return sum / half(total);
}
