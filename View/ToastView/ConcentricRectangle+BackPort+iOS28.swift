//
//  ConcentricRectangle+BackPort+iOS28.swift
//  animation
//
//  Created on 3/17/26.
//
//  Learning point
//  ──────────────
//  Backport of iOS 26's `ConcentricRectangle` shape to iOS 18.
//  A concentric rectangle is a rounded rect whose CORNER RADIUS
//  changes per-corner so that the visible inner corners stay
//  geometrically *parallel* to the device's hardware corners —
//  no matter where the view sits or how much it's padded.
//
//  Why "concentric" matters
//  ────────────────────────
//  Apple's iPhone hardware corners have a continuous ~50pt
//  radius. If you draw a card with a fixed `cornerRadius: 30` and
//  pad it close to the edge, the card's corners and the device's
//  corners CURVE AT DIFFERENT RATES — your card looks subtly
//  wrong (the gap between card-corner and device-corner is wider
//  at one point than another). Concentric rectangle fixes this
//  by tightening or relaxing each corner so the gap stays
//  uniform. iOS 26 ships this natively as `ConcentricRectangle`;
//  this file recreates it for iOS 18 by READING the device
//  corner radius and computing per-corner radii from the view's
//  global frame.
//
//  How the per-corner math works
//  ─────────────────────────────
//      let leading  = globalRect.minX
//      let trailing = deviceSize.width - globalRect.maxX
//      let top      = globalRect.minY
//      let bottom   = deviceSize.height - globalRect.maxY
//
//      let tl = max(deviceCorner - max(top, leading),    0)
//      let bl = max(deviceCorner - max(bottom, leading), 0)
//      let bt = max(deviceCorner - max(bottom, trailing),0)
//      let tt = max(deviceCorner - max(top, trailing),   0)
//
//  Each corner's radius equals the device corner radius MINUS
//  the maximum distance to its two adjoining screen edges
//  (clamped at 0). The further the view is from that corner of
//  the device, the smaller the inner radius — so a card placed
//  in the bottom-right gets a sharp top-left corner and a curved
//  bottom-right corner that exactly mirrors the iPhone bezel.
//
//  Why `extractDeviceCornerRadius` walks the EnvironmentValues
//  ───────────────────────────────────────────────────────────
//  iOS exposes the device corner radius via a private
//  `DisplayCornerRadiusKey` environment value. There's no
//  public accessor, so the function `String(describing: env)`
//  dumps the environment to text and `regex /…/` extracts the
//  numeric value. Brittle — Apple could rename the key — but
//  the only known way pre-iOS 26.
//
//  The `isUniform` parameter
//  ─────────────────────────
//  When `true`, every corner uses the LARGEST of the four
//  computed radii. Useful when you want a "soft pill" look that
//  doesn't change per position. When `false`, each corner gets
//  its own radius (true concentricity).
//
//  Why `globalRect` is tracked via `onGeometryChange(for: CGRect.self)`
//  ────────────────────────────────────────────────────────────────────
//  The `Shape.path(in:)` only knows the local rect (size). To
//  know WHERE on screen the view is, we observe the global
//  frame via `onGeometryChange` and store it in `@State`. Each
//  re-evaluation of `path(in:)` reads that global rect and
//  recomputes the four corners.
//
//  `nonisolated` on `path(in:)` and `extractDeviceCornerRadius`
//  ────────────────────────────────────────────────────────────
//  `Shape.path(in:)` may be called from any actor context during
//  layout passes; marking it `nonisolated` is required when the
//  enclosing type stores main-actor-isolated state (we capture
//  the env values in init). `@unchecked Sendable` opts out of
//  Sendable checking for the captured env reference.
//
//  Key APIs
//  ────────
//  • `ConcentricRectangle()` (iOS 26+) — native shape; this file
//    is the iOS 18 backport.
//  • `.onGeometryChange(for: CGRect.self) { $0.frame(in: .global) }` —
//    track view's screen position.
//  • Custom `Shape` + `.clipShape` + `.contentShape` — clip both
//    visual AND hit-test.
//  • `Path.addRoundedRect(in:cornerRadii:)` — per-corner radii
//    (iOS 16+).
//
//  How to apply
//  ────────────
//  Use this whenever a view sits close to the screen edge and
//  needs to LOOK like part of the device chassis: floating
//  toolbars, edge-attached cards, music player chrome, full-
//  screen modal sheets that extend into safe areas. Once on
//  iOS 26, switch to the native `ConcentricRectangle()`.
//
//  See also
//  ────────
//  • LiquidGlassToastView+IOS26.swift — sister iOS 26 file
//    using the native `ConcentricRectangle` for toast capsules.
//  • View/Sheet/iOS26StyleFloatingSheet.swift — same per-device
//    corner-radius matching applied to sheet chrome.
//

import SwiftUI

struct ConcentricRectangleIOS18DemoView: View {
    @Environment(\.self) private var env
    @State private var padding: CGFloat = 20
    var body: some View {
        ZStack {
            if #available(iOS 26, *) {
                ConcentricRectangle()
                    .padding(10)
            }

            let deviceCornerRadius = extractDeviceCornerRadius(env) ?? 0
            RoundedRectangle(cornerRadius: deviceCornerRadius, style: .continuous)
                .inset(by: 10)
                .fill(.red.opacity(0.9))
                .concentricClipShape(true)

            Slider(value: $padding, in: 0 ... 100)
                .padding(20)
        }
        .padding(padding)
        .ignoresSafeArea()
    }
}

extension View {
    func concentricClipShape(_ isUniform: Bool) -> some View {
        modifier(ConcentricClipShape(isUniform: isUniform))
    }
}

private struct ConcentricClipShape: ViewModifier {
    var isUniform: Bool
    @State private var globalRect: CGRect = .zero
    @Environment(\.self) private var env
    func body(content: Content) -> some View {
        let clipShape = BackportedConcentricRectangle(env: env, globalRect: globalRect, isUniform: isUniform)
        content
            .clipShape(clipShape)
            .contentShape(clipShape)
            .onGeometryChange(for: CGRect.self) {
                $0.frame(in: .global)
            } action: { newValue in
                globalRect = newValue
            }
    }
}

struct CustomShapeCRDemoView: View {
    @Environment(\.self) private var env
    @State private var padding: CGFloat = 20
    var body: some View {
        ZStack {
            if #available(iOS 26, *) {
                ConcentricRectangle()
                    .padding(10)
            }

            GeometryReader {
                let rect = $0.frame(in: .global)
                BackportedConcentricRectangle(env: env, globalRect: rect, isUniform: true)
                    .fill(.red.opacity(0.5))
            }

            Slider(value: $padding, in: 0 ... 100)
                .padding(20)
        }
        .padding(padding)
        .ignoresSafeArea()
    }
}

/// create customized shape for back port Concentric Rectangle to iOS 18
struct BackportedConcentricRectangle: Shape, @unchecked Sendable {
    let env: EnvironmentValues
    var globalRect: CGRect
    var isUniform: Bool
    @MainActor
    init(env: EnvironmentValues, globalRect: CGRect, isUniform: Bool = false) {
        self.env = env
        self.globalRect = globalRect
        self.isUniform = isUniform

        if let screen = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.screen {
            deviceSize = screen.bounds.size
        } else {
            deviceSize = .zero
        }
    }

    private let deviceSize: CGSize

    nonisolated func path(in rect: CGRect) -> Path {
        Path { path in
            // Tip: the per-corner radius formula is the load-bearing
            // bit. Each inner radius = deviceCornerRadius minus the
            // larger of the two distances to the corresponding screen
            // edges. Clamp at 0 so corners far from any device corner
            // collapse to sharp 90°. `isUniform = true` flattens all
            // four to the largest computed value (soft-pill look).
            let cornerRadius = extractDeviceCornerRadius(env) ?? 0
            let leading = globalRect.minX
            let trailing = deviceSize.width - globalRect.maxX
            let top = globalRect.minY
            let bottom = deviceSize.height - globalRect.maxY

            let tl = max(cornerRadius - max(top, leading), 0)
            let bl = max(cornerRadius - max(bottom, leading), 0)
            let bt = max(cornerRadius - max(bottom, trailing), 0)
            let tt = max(cornerRadius - max(top, trailing), 0)

            let maxValue = max(tl, max(bl, max(bt, tt)))

            path.addRoundedRect(in: rect, cornerRadii: .init(
                topLeading: isUniform ? maxValue : tl,
                bottomLeading: isUniform ? maxValue : bl,
                bottomTrailing: isUniform ? maxValue : bt,
                topTrailing: isUniform ? maxValue : tt
            ))
        }
    }
}

/// Tip: brittle but functional — there is no public API to read the
/// device's hardware corner radius pre-iOS 26.
/// `String(describing: env)` dumps the entire `EnvironmentValues` to
/// text; the regex extracts `Optional(53.33)` (or whatever value)
/// from the line containing `DisplayCornerRadiusKey`. If Apple
/// renames or restructures the key, the regex fails and we fall back
/// to 0 (sharp corners). Replace with native iOS 26+ APIs when
/// raising the deployment target.
extension View {
    nonisolated func extractDeviceCornerRadius(_ env: EnvironmentValues) -> CGFloat? {
        let envText = String(describing: env)
        let pattern = /EnvironmentPropertyKey<DisplayCornerRadiusKey> = Optional\(([\d.]+)\)/
        guard let firstMatch = envText.firstMatch(of: pattern),
              let value = Float(firstMatch.1)
        else {
            return nil
        }
        return CGFloat(value)
    }
}

#Preview {
    CustomShapeCRDemoView()
}

#Preview {
    ConcentricRectangleIOS18DemoView()
}
