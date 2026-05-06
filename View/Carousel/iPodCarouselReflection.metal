//
//  iPosCarouselReflection.metal
//  animation
//
//  Created on 5/5/26.
//
// Cover Flow / iPod-style mirror reflection drawn beneath each carousel
// card. The shader is invoked from Swift via:
//   .layerEffect(
//       ShaderLibrary.carouselCoverFlowReflection(
//           .float(proxy.size.height),  // contentHeight
//           .float(reflectionGap),
//           .float(reflectionFade),
//           .float(reflectionDim)
//       ),
//       maxSampleOffset: proxy.size
//   )
//
// Learning points
// ───────────────────────────────────────────────────────────────────────
// 1. `[[stitchable]]` + `SwiftUI::Layer` is the SwiftUI ↔ Metal bridge.
//    The `[[stitchable]]` attribute makes this free function discoverable
//    by `ShaderLibrary.<funcName>(...)` on the Swift side. The first two
//    parameters are *implicit* and supplied by SwiftUI itself:
//      • `float2 position` — the destination pixel currently being shaded
//        (in points, in the layer's local coordinate space).
//      • `SwiftUI::Layer layer` — a sampler over the rendered SwiftUI
//        view; `layer.sample(pos)` returns the view's color at `pos`.
//    Every parameter *after* `layer` must be passed from Swift in order,
//    wrapped as `.float(...)`, `.float2(...)`, `.color(...)`, etc.
//
// 2. `layerEffect` vs `colorEffect` — why this needs the former.
//    `colorEffect` only lets you transform the pixel at `position`.
//    `layerEffect` lets you *sample anywhere* in the layer, which is
//    exactly what a reflection needs (read pixel at `(x, contentHeight-y)`
//    and write it at `(x, y)` below the original). The trade-off: you must
//    declare `maxSampleOffset:` so SwiftUI knows how far the shader will
//    reach when allocating the backing texture.
//
// 3. The drawable area is *larger* than the source view.
//    Because the Swift side passes `maxSampleOffset: proxy.size`, the
//    shader is asked about pixels with `position.y` greater than
//    `contentHeight`. The function is split into three vertical bands:
//      • `y < contentHeight`              → passthrough original pixel.
//      • `contentHeight ≤ y < start`      → transparent gap.
//      • `y ≥ start`                      → mirrored, faded reflection.
//
// 4. Mirror math.
//    `posY = position.y - start` is the distance into the reflection band.
//    Sampling at `(position.x, contentHeight - posY)` flips the image
//    vertically: the row just under the gap samples the *bottom* of the
//    original, and rows further down sample progressively higher rows —
//    classic mirror reflection. The `pos.y < 0.0` guard skips samples
//    that would read above the original view.
//
// 5. Fade curve — `pow(1 - progress, fade)`.
//    `progress = posY / contentHeight` is 0 at the top of the reflection
//    and 1 at the bottom. `pow(1 - progress, fade)` produces:
//      • `fade = 1`  → linear fade,
//      • `fade > 1`  → reflection dies out *faster* near the bottom (the
//        Cover Flow look — opaque near the card, gone halfway down).
//    The result is then multiplied by `dim` (a flat brightness scalar
//    < 1) so even the brightest reflected pixel is darker than the source.
//
// 6. Premultiplied alpha out of `layer.sample`.
//    `layer.sample(pos)` returns *premultiplied* RGBA. Multiplying the
//    whole `half4` by `alpha` and `dim` therefore correctly attenuates
//    both color and alpha together — no separate `.a *= alpha` needed.
// ───────────────────────────────────────────────────────────────────────

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

[[stitchable]]
half4 carouselCoverFlowReflection(
  float2 position,
  SwiftUI::Layer layer,
  float contentHeight,
  float reflectionGap,
  float fade,
  float dim
) {
    /// Original content
    if (position.y < contentHeight) {
        return layer.sample(position);
    }

    /// Transparent gap between content and reflection
    float start = contentHeight + reflectionGap;
    if (position.y < start) {
        return half4(0);
    }

    /// Reflection (Mirror Vertically)
    float posY = position.y - start;
    float2 pos = float2(position.x, contentHeight - posY);

    if (pos.y < 0.0) {
        return half4(0);
    }

    /// Fade out reflection
    float progress = posY / contentHeight;
    float alpha = pow(1.0 - clamp(progress, 0.0, 1.0), fade);

    half4 color = (layer.sample(pos) * alpha) * half4(dim);
    return color;
}
