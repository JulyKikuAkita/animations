//
//  Pixellate.metal
//  animation

#include <metal_stdlib>
using namespace metal;

using namespace metal;
[[stitchable]] float2 pixellate(float2 position, float size) {
    float2 pixellatedPosition = round(position / size) * size;
    return pixellatedPosition;
}
