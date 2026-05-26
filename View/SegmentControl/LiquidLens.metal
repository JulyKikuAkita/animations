//
//  LiquidLens.metal
//  animation
//
//  A SwiftUI `layerEffect` Metal shader that fakes a glass-pill refraction
//  on top of any layer (used by GlassSegmentedControlView for the moving
//  selection capsule). Pixels inside the capsule are sampled from a
//  slightly shifted position to mimic light bending through a lens; pixels
//  outside the capsule pass through unchanged.
//
//  When to reach for a Metal shader instead of pure SwiftUI:
//  - The effect needs per-pixel sampling of what's already on screen
//    (refraction, displacement, blur with custom falloff). SwiftUI's
//    blendModes / materials can't do this.
//  - You want the effect to track geometry that animates every frame
//    (here, the capsule slides as the user scrolls); a shader runs on the
//    GPU and stays smooth.
//  - You're targeting iOS 17+ where `View.layerEffect(ShaderLibrary.<fn>)`
//    is available.
//
//  How SwiftUI calls in:
//      content.layerEffect(
//          ShaderLibrary.liquidLens(.float2(size), .float(x), ...),
//          maxSampleOffset: .init(width: 200, height: 100)
//      )
//  `maxSampleOffset` MUST be >= the largest distance this shader reads
//  away from `position` — otherwise SwiftUI clips the sample and you get
//  black edges. Bump it up if you increase `refractionAmount`.
//
//  The `[[stitchable]]` attribute is what lets SwiftUI's `ShaderLibrary`
//  find the function by name at runtime.

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>

using namespace metal;

/// Signed distance function (SDF) for a capsule centered at the origin.
/// Returns a negative value inside the shape, zero on the edge, positive
/// outside. SDFs are the standard way to do shape-aware effects in
/// shaders because the distance itself drives both hit-testing and the
/// smooth edge falloff used below.
float distanceToCapsule(float2 position, float2 halfSize, float radius) {
    float2 capPos = abs(position) - halfSize + radius;
    return length(max(capPos, 0.0)) + min(max(capPos.x, capPos.y), 0.0) - radius;
}

/// `position`         — current pixel in layer space (provided by SwiftUI).
/// `layer`            — sampler over the underlying SwiftUI content.
/// `size`             — capsule width/height in points.
/// `positionX`        — capsule center offset on the x-axis (negative of the
///                      scroll's midX in the demo, so the pill stays centered
///                      while content scrolls underneath).
/// `refractionAmount` — peak pixel displacement near the rim (pixels).
/// `refractionDepth`  — how far inward the rim falloff extends (pixels);
///                      larger = softer, more glass-like, smaller = sharper edge.
[[stitchable]] half4 liquidLens(
float2 position,
SwiftUI::Layer layer,
float2 size,
float positionX,
float refractionAmount,
float refractionDepth
) {
    float2 pillCenter = size * 0.5 + float2(positionX, 0.0);
    float2 local = position - pillCenter;
    float2 halfSize = size * 0.5;
    float radius = size.y * 0.5;
    float dist = distanceToCapsule(local, halfSize, radius);
    if (dist > 0.0) {
        return layer.sample(position);
    }

    float2 outward = normalize(float2(
      distanceToCapsule(local + float2(1, 0), halfSize, radius) - distanceToCapsule(local - float2(1, 0), halfSize, radius),
      distanceToCapsule(local + float2(0, 1), halfSize, radius) - distanceToCapsule(local - float2(0, 1), halfSize, radius)
    ));

    float depthInside = -dist;
    float edgePxmy = 1.0 - smoothstep(0.0, refractionDepth, depthInside);
    float bend = edgePxmy * edgePxmy * refractionAmount;
    return layer.sample(position - outward * bend);
}
