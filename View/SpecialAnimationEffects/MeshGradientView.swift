//
//  MeshGradientView.swift
//  animation
//
//  Learning point
//  ──────────────
//  Interactive playground for iOS 18's new `MeshGradient` — a 2D
//  bilinear-interpolated gradient where each control point in a
//  W×H grid contributes its own colour. Drag any of the 9 black
//  handles to warp the gradient in real time.
//
//  Why a 3×3 mesh
//  ──────────────
//  `MeshGradient` interpolates colour across the surface defined
//  by `points: [SIMD2<Float>]` (each in [0,1]×[0,1] UV space) and
//  `colors: [Color]`. A 3×3 mesh is the smallest size that allows
//  a CENTRE point distinct from corners — enough to create
//  organic-looking blobs by dragging just the centre. Larger
//  meshes (4×4, 5×5) get smoother gradients but more handles to
//  manage.
//
//  Three reusable mechanics
//  ────────────────────────
//    1. **`@State` array of `MeshPoint` per row** — each handle
//       owns its (x, y) UV coordinate AND a screen-space `offset`
//       so the visible black dot tracks the touch independently
//       of the gradient computation.
//    2. **Named `.coordinateSpace("MESH")` for the gesture** —
//       `value.location` from the drag is in the gradient view's
//       own pixel space, so we can map it directly to UV via
//       `x / size.width`. Without the name, location would be in
//       window coords and require subtracting the view's origin.
//    3. **Two stored offsets per handle** (`offset` + `lastOffset`) —
//       `lastOffset` is the cumulative drag distance from prior
//       gestures; `offset` is `lastOffset + currentGesture.translation`.
//       Adding them on `onChanged` and copying on `onEnded` is the
//       standard "drag persists across gestures" pattern.
//
//  Why `SIMD2<Float>` (not `CGPoint`)
//  ──────────────────────────────────
//  `MeshGradient`'s `points:` parameter is `[SIMD2<Float>]` for
//  GPU-friendly layout. The file-local `.p(_ point:)` helper
//  bridges from the project's `MeshPoint` struct to `SIMD2<Float>`.
//
//  Key APIs
//  ────────
//  • `MeshGradient(width:height:points:colors:)` (iOS 18+) — the
//    primitive itself.
//  • `.coordinateSpace(name:)` + `DragGesture(coordinateSpace: .named(...))` —
//    pin gesture coords to the view's own space.
//  • `SIMD2<Float>` — vectorised point type for GPU-bound APIs.
//
//  How to apply
//  ────────────
//  Use as the foundation for animated brand backgrounds, mood
//  visualisers, music-app art, or any "organic blob gradient"
//  surface. Combine with `.animation(...)` on the points to make
//  the gradient flow continuously (drive points from a
//  `TimelineView` clock).
//
//  See also
//  ────────
//  • View/Music/* — likely call sites for gradient-as-background.
//  • MessengerGradientEffectView.swift — sister demo that uses a
//    fixed `LinearGradient` instead of MeshGradient.
//

import SwiftUI

@available(iOS 18.0, *)
struct MeshGradientView: View {
    @State private var top: [MeshPoint] = [
        .init(x: 0, y: 0), .init(x: 0.5, y: 0), .init(x: 1, y: 0),
    ]

    @State private var center: [MeshPoint] = [
        .init(x: 0, y: 0.5), .init(x: 0.5, y: 0.5), .init(x: 1, y: 0.5),
    ]

    @State private var bottom: [MeshPoint] = [
        .init(x: 0, y: 1), .init(x: 0.5, y: 1), .init(x: 1, y: 1),
    ]

    var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                .p(top[0]), .p(top[1]), .p(top[2]),
                .p(center[0]), .p(center[1]), .p(center[2]),
                .p(bottom[0]), .p(bottom[1]), .p(bottom[2]),
            ],
            colors: [
                .red, .orange, .pink,
                .purple, .green, .yellow,
                .indigo, .mint, .cyan,
            ]
        )
        .overlay {
            GeometryReader {
                let size = $0.size
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        circleView($top[0], size)
                        circleView($top[1], size)
                        circleView($top[2], size, isLast: true)
                    }

                    HStack(spacing: 0) {
                        circleView($center[0], size)
                        circleView($center[1], size)
                        circleView($center[2], size, isLast: true)
                    }
                    .frame(maxHeight: .infinity)

                    HStack(spacing: 0) {
                        circleView($bottom[0], size)
                        circleView($bottom[1], size)
                        circleView($bottom[2], size, isLast: true)
                    }
                }
            }
        }
    }

    // swiftlint:disable identifier_name

    @ViewBuilder
    func circleView(_ point: Binding<MeshPoint>,
                    _ size: CGSize, isLast: Bool = false) -> some View
    {
        Circle()
            .fill(.black)
            .frame(width: 10, height: 10)
            .contentShape(.rect)
            .offset(point.wrappedValue.offset)
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .named("MESH"))
                    .onChanged { value in
                        let location = value.location
                        let x = Float(location.x / size.width) // mesh point needs to between [0,1]
                        let y = Float(location.y / size.height)

                        point.wrappedValue.x = x
                        point.wrappedValue.y = y

                        let offset = value.translation
                        let lastOffset = point.wrappedValue.lastOffset

                        point.wrappedValue.offset = offset + lastOffset
                    }
                    .onEnded { _ in
                        point.wrappedValue.lastOffset = point.wrappedValue.offset
                    }
            )

        if !isLast {
            Spacer(minLength: 0)
        }
    }
}

struct MeshPoint {
    var x: Float
    var y: Float

    init(x: Float, y: Float) {
        self.x = x
        self.y = y
    }

    var offset: CGSize = .zero
    var lastOffset: CGSize = .zero
}

// swiftlint:enable identifier_name

private extension SIMD2<Float> {
    static func p(_ point: MeshPoint) -> Self {
        .init(point.x, point.y)
    }
}

private extension CGSize {
    static func + (lhs: CGSize, rhs: CGSize) -> CGSize {
        .init(
            width: lhs.width + rhs.width,
            height: lhs.height + rhs.height
        )
    }
}

#Preview {
    if #available(iOS 18.0, *) {
        MeshGradientView()
    } else {
        // Fallback on earlier versions
    }
}
