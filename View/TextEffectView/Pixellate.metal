//
//  Pixellate.metal
//  animation
//
//  Tip: this is a stitchable distortion shader — SwiftUI runtime
//  composes it into its own pipeline (no Metal setup ceremony).
//
//  Signature: `float2 pixellate(float2 position, float size)`
//    • `position`     — the pixel coordinate SwiftUI is asking the
//                       shader to sample for.
//    • `size`         — Swift-side argument forwarded via
//                       `Shader(function:arguments:)`. Acts as the
//                       cell size of the pixel grid.
//    • return value   — the position to ACTUALLY sample from (the
//                       distortion). Returning `position` unchanged is
//                       a no-op.
//
//  Implementation: `round(position / size) * size` snaps every input
//  coordinate to the nearest multiple of `size`. All pixels inside
//  one cell of the grid resolve to the same source pixel, producing
//  the chunky pixellate look. Larger `size` → bigger blocks.

#include <metal_stdlib>

using namespace metal;
[[stitchable]] float2 pixellate(float2 position, float size) {
    float2 pixellatedPosition = round(position / size) * size;
    return pixellatedPosition;
}
