//
//  PageCurlEffect.metal
//  animation
//
//  Created on 12/25/25.
// custom Metal shader for SwiftUI based on reactive: https://www.youtube.com/watch?v=xNZCQvtnhIU

#include <metal_stdlib>
#include <SwiftUI/SwiftUI.h>
using namespace metal;

// Helper: build a 3x3 matrix that scales around an arbitrary center point.
//
// Learning point — affine transforms in 2D need 3x3 matrices (homogeneous coords)
// because pure 2x2 matrices can't represent translation. We use the standard
// "translate to origin -> scale -> translate back" trick. Matrix multiplication
// is right-to-left, so the rightmost matrix in the product is applied first:
//     result = moveBack * scaleIt * moveToOrigin
//     point' = moveBack * (scaleIt * (moveToOrigin * point))
//
// Note: Metal stores matrices in column-major order, so each `float3(...)`
// below is a *column* of the matrix, not a row. The translation components
// therefore live in the third column (rows 0 and 1 of column 2).
float3x3 scaleAroundCenter(float2 scale, float2 center) {
    float3x3 moveToOrigin = float3x3(
         float3(1, 0, 0),
         float3(0, 1, 0),
         float3(-center.x, -center.y, 1)
     );

    float3x3 scaleIt = float3x3(
         float3(scale.x, 0, 0),
         float3(0, scale.y, 0),
         float3(0, 0, 1)
     );

    float3x3 moveBack = float3x3(
         float3(1, 0, 0),
         float3(0, 1, 0),
         float3(center.x, center.y, 1)
     );

    return moveBack * scaleIt * moveToOrigin;
}

// Apply a 3x3 affine matrix to a 2D point.
// We promote (x, y) -> (x, y, 1); the trailing 1 is what lets translations
// in the matrix's third column actually take effect.
float2 transform(float2 point, float3x3 matrix) {
    float3 p = float3(point, 1.0);
    float3 result = matrix * p;
    return result.xy;
}

// Check if a point is inside a rounded rectangle.
//
// Learning point — a rounded rect is a regular rect with quarter-circle
// "cutouts" at each corner. The fast hit-test is:
//   1. Reject anything outside the bounding rect.
//   2. For each corner, if the point lies in that corner's square region,
//      check distance to the inner corner-center (the center of the
//      quarter-circle). Inside the circle => inside the rounded rect.
//   3. Otherwise the point is in the straight-edge interior — accept.
//
// `rect` is packed as (minX, minY, maxX, maxY).
// `corners` is packed as (topLeft, topRight, bottomLeft, bottomRight) radii.
bool isInside(float2 point, float4 rect, float4 corners) {
    bool inRect = point.x > rect.x && point.x < rect.z &&
                  point.y > rect.y && point.y < rect.w;

    if (!inRect) return false;

    // Checking all the four corners
    // Top left
    float topLeft = corners.x;
    if (point.x < rect.x + topLeft && point.y < rect.y + topLeft) {
        float2 cornerCenter = float2(rect.x + topLeft, rect.y + topLeft);
        return length(point - cornerCenter) < topLeft;
    }

    // Top Right
    float topRight = corners.y;
    if (point.x > rect.z - topRight && point.y < rect.y + topRight) {
        float2 cornerCenter = float2(rect.z - topRight, rect.y + topRight);
        return length(point - cornerCenter) < topRight;
    }

    // Bottom Left
    float bottomLeft = corners.z;
    if (point.x < rect.x + bottomLeft && point.y > rect.w - bottomLeft) {
        float2 cornerCenter = float2(rect.x + bottomLeft, rect.w - bottomLeft);
        return length(point - cornerCenter) < bottomLeft;
    }

    // Bottom Right
    float bottomRight = corners.w;
    if (point.x > rect.z - bottomRight && point.y > rect.w - bottomRight) {
        float2 cornerCenter = float2(rect.z - bottomRight, rect.w - bottomRight);
        return length(point - cornerCenter) < bottomRight;
    }
    return true;
}

// Stitchable shader entry point — invoked once per pixel by SwiftUI's
// `.layerEffect` modifier. The `[[stitchable]]` attribute tells the Metal
// compiler this function can be linked into SwiftUI's render pipeline.
//
// Mental model of the curl
// ------------------------
// Imagine the page being rolled around an invisible vertical cylinder of
// radius `radius`. The cylinder's near edge sits at x = curlX. As `drag`
// grows, curlX moves left and the cylinder eats more of the page.
//
// Geometry split (all driven by `dist = pos.x - curlX`):
//
//     ...curled-away gap...|...behind the curl(dist > radius)
//                          |     ╭─── on the cylinder (0 < dist <= radius)
//          flat page       |   ╱
//          (dist <= 0)     |──┤
//                          |   ╲___ front face (dist > 0, near side)
//                          |    \__ back face  (dist > 0, far side)
//                        curlX
//
// For each pixel, we figure out which region it's in and either:
//   * sample the layer at a remapped position (to "unroll" the curl), or
//   * draw shadow / nothing.
[[stitchable]] half4 pageCurlEffect(
    float2 pos,                  // current pixel in layer coords
    SwiftUI::Layer layer,        // the un-curled source layer we sample from
    float drag,                  // how far the curl has progressed (px from right edge)
    float2 size,                 // layer size in px
    float4 corners,              // rounded-rect corner radii (TL, TR, BL, BR)
    float2 center,               // anchor for the parallax scale-around (usually layer center)
    float radius,                // curl cylinder radius in px
    float curlShadow,            // 0..1 strength of shadow on the front face near the fold
    float underneathShadow       // 0..1 alpha of the shadow cast on the page below
) {
    // Metal's <metal_stdlib> exposes M_PI_F (float π), M_PI_2_F (π/2), etc.
    // Prefer these over a hand-rolled constant — `3.14` is ~0.05% short of π
    // and the error compounds in arc-length / angle math below.
    const float PI = M_PI_F;
    float curlX = size.x - drag; // x-position of the cylinder's near edge
    float dist = pos.x - curlX;  // signed distance from this pixel to the curl
    float4 bounds = float4(0, 0, size.x, size.y);
    half4 color = half4(0.0);

    // ----- Region 1: behind the cylinder ----------------------------------
    // The page has fully curled away here. We're seeing whatever was below
    // it (the next page, the background, etc). We only paint a soft shadow
    // that fades out the further we are from the cylinder.
    if (dist > radius) {
        color = half4(0, 0, 0, 0);
        if (isInside(pos, bounds, corners)) {
            // fade goes 0 -> 1 as we move away from the curl;
            // mix() returns underneathShadow at the curl edge, 0 far away.
            float fade = (dist - radius) / radius;
            color.a = mix(underneathShadow, 0.0, fade);
        }

    // ----- Region 2: on the curling cylinder ------------------------------
    // The page is wrapping around the cylinder. For a given screen x in
    // (0, radius] from curlX, there are TWO points on the cylinder mapping
    // to it: one on the front (near) side and one on the back (far) side.
    // We compute both candidate samples and pick whichever lies inside the
    // page bounds. If both are out of bounds, we draw the underneath shadow.
    } else if (dist > 0.0) {
        // Angle from the cylinder's top to this pixel's column, measured
        // around the cylinder axis. asin maps screen-x distance back to
        // an angle on the circle: dist = radius * sin(angle).
        float angle = asin(dist / radius);

        // Arc length is how far along the rolled-up paper this column is.
        // - Front: short arc from the fold to the front-side point.
        // - Back:  long arc going over the top to the back-side point.
        // Adding arcFront/arcBack to curlX "unrolls" the cylinder back onto
        // the flat page so we can sample the original texture.
        float arcFront = angle * radius;
        float arcBack = (PI - angle) * radius;

        // Tiny vertical scale-around-center adds a touch of fake perspective
        // (the front of the curl bulges slightly, the back compresses).
        // sin(PI/2 + angle) == cos(angle), so this is a cheap parallax fudge,
        // not a true perspective projection.
        float2 scaleFront = float2(1.0 + (1.0 - sin(PI/2.0 + angle)) * 0.1);
        float3x3 matrixFront = scaleAroundCenter(scaleFront, center);
        float2 posFront = transform(pos, matrixFront);
        float2 sampleFront = float2(curlX + arcFront, posFront.y);

        float2 scaleBack = float2(1.1 + sin(PI/2.0 + angle) * 0.1);
        float3x3 matrixBack = scaleAroundCenter(scaleBack, center);
        float2 posBack = transform(pos, matrixBack);
        float2 sampleBack = float2(curlX + arcBack, posBack.y);

        // Order matters: back face is checked first because it overlaps the
        // front in the curl region (the paper occludes itself at the fold).
        if (isInside(sampleBack, bounds, corners)) {
            // Back face — what you'd see looking at the underside of the page.
            color = half4(layer.sample(sampleBack));

            // Whitewash to fake the back of paper being lighter / less inky.
            // mix(a, b, t) = a*(1-t) + b*t, so 0.7 blends 70% toward white.
            half3 white = half3(1.0, 1.0, 1.0);
            float fadeAmount = 0.7;
            color.rgb = mix(color.rgb, white, fadeAmount);

        } else if (isInside(sampleFront, bounds, corners)) {
            // Front face — the side of the page facing the camera.
            color = half4(layer.sample(sampleFront));

            // Self-shadow near the fold: darker as we approach the cylinder
            // edge (dist -> radius), lighter as we leave the curl (dist -> 0).
            // pow(..., 1.0) is a no-op today; it's left in as a hook for
            // tuning falloff curves (try 0.5 for softer, 2.0 for sharper).
            float shadow = pow(clamp((radius - dist) / radius, 0.0, 1.0), 1.0);
            float darken = 1.0 - (curlShadow * (1.0 - shadow));
            color.rgb *= darken;

        } else {
            // Neither sample hit the page (e.g. we're in a corner cutout).
            // Fall through to the underneath shadow so the curl casts a
            // shadow even where the page itself has no pixel to show.
            color = half4(0, 0, 0, underneathShadow);
        }

    // ----- Region 3: ahead of the curl ------------------------------------
    // dist <= 0 — we haven't reached the curl yet. Two sub-cases:
    //   (a) This pixel is inside the rect that the *back* of the curl is
    //       projecting onto — i.e. we're seeing the back face peeking out
    //       past the cylinder's far edge. Sample the page at curlX + |dist|
    //       + PI*radius, which is "the far side of the cylinder, unrolled."
    //   (b) Otherwise this is the un-curled flat page — sample as-is.
    } else {
        float2 scaleRevealed = float2(1.2);
        float3x3 matrixRevealed = scaleAroundCenter(scaleRevealed, center);
        float2 posRevealed = transform(pos, matrixRevealed);
        // PI*radius == half the cylinder circumference; abs(dist) accounts
        // for how far past the far edge we are. Together they give the
        // x-coord where this pixel's back-face content lives on the flat page.
        float2 sampleRevealed = float2(curlX + abs(dist) + PI * radius, posRevealed.y);

        if (isInside(sampleRevealed, bounds, corners)) {
            // (a) Back of the curl visible past the fold.
            color = half4(layer.sample(sampleRevealed));

            // Same whitewash as Region 2's back face for visual consistency.
            half3 white = half3(1.0, 1.0, 1.0);
            float fadeAmount = 0.7;
            color.rgb = mix(color.rgb, white, fadeAmount);
        } else {
            // (b) Plain un-curled page — pass through.
            color = half4(layer.sample(pos));
        }
    }
    return color;
}
