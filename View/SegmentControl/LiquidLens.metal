//
//  LiquidLens.metal
//  animation

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>

using namespace metal;
float distanceToCapsule(float2 position, float2 halfSize, float radius) {
    float2 capPos = abs(position) - halfSize + radius;
    return length(max(capPos, 0.0)) + min(max(capPos.x, capPos.y), 0.0) - radius;
}

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
