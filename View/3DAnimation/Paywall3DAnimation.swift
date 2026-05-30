//
//  Paywall3DAnimation.swift
//  animation
//
//  Created on 2/4/26.
//  Standalone demo (not wired into the app's demo browser; preview-only).
//  iOS 18+ — uses the `@Animatable` macro on the modifier.
//
//  Learning point
//  ──────────────
//  Tilted icon-ring animation typical of premium / paywall screens:
//  a dashed circle is tilted in 3D, icons orbit along the same
//  tilted ellipse, and the whole thing reveals (trim 0→1) then
//  spins forever. Read this file as TWO interlocking pieces:
//
//    1. The RING — a `Circle().stroke(...).rotation3DEffect(62°, X)
//       .rotation3DEffect(-20°, Z)`. SwiftUI does the math for us;
//       we just pick angles.
//    2. The ICONS — placed by hand around an ellipse that MATCHES
//       the projected ring shape. We can't reuse the ring's
//       `rotation3DEffect` because applying it to icons distorts
//       them (squash, perspective skew, font rendering). So we
//       compute (x, y) on the projected ellipse manually.
//
//  The 62° tilt appears twice (line ~70 and inside the icon `cos`
//  call below) and MUST stay in sync — it's the load-bearing magic
//  number. Same for `-20°` on the Z-axis vs. `+20°` per-icon
//  counter-rotation.
//
//  Reveal pipeline (driven by `trim` 0→1):
//    • Ring stroke: `Circle().trim(from: 0, to: trim)` draws clockwise.
//    • Icons: each icon owns a 1/N slice of `trim`; its `scaleProgress`
//      ramps 0→1 over only its slice — so icons "pop in" sequentially
//      as the stroke sweeps past them.
//
//  After the reveal, `rotation` ramps 0→360° on a 15s
//  `repeatForever(autoreverses: false)` linear loop and is fed into
//  BOTH the ring's `rotationEffect` and each icon's angle, so they
//  stay locked.
//
//  Key APIs
//  ────────
//  • `@Animatable` + `@AnimatableIgnored` — iOS 18+ macro that
//    synthesises `AnimatableData` for the float properties so
//    SwiftUI can interpolate `trim` and `rotation` smoothly. The
//    array/font/color stay non-animatable (no math on them).
//  • `Circle().trim(from:to:).stroke(_, style: StrokeStyle(dash:))` —
//    standard dashed-circle stroke; `dash:[dashLength]` paired with
//    `dashPhase: -dashLength/2` puts a gap centred on each icon.
//  • `rotation3DEffect(_:axis:perspective: 0)` — `perspective: 0`
//    is intentional; we want a flat orthographic tilt, not vanishing-
//    point perspective which would scale far icons unevenly.
//  • Manual ellipse math: `x = cos(θ)·r`,
//    `y = sin(θ)·r·cos(tilt)` — the `cos(tilt)` factor is the
//    Y-projection of an X-axis tilt; that's how the icons trace the
//    same ellipse the tilted circle draws.
//
//  How to apply
//  ────────────
//  Drop in any SF Symbols list to brand a paywall, onboarding hero,
//  or "feature wheel" UI. The two angles (62°, -20°) are the only
//  visual knobs worth touching; if you change either, update the
//  matching constant in the icon math below.
//
//  See also
//  ────────
//  • View/SpecialAnimationEffects/MetaballAnimation_iOS26.swift —
//    same `@Animatable` + `@AnimatableIgnored` pattern on a
//    different effect.
//  • View/LandingPages/LoopingKeyframeAnimation+iOS26.swift — has
//    a fuller write-up of `@Animatable`'s synthesis behaviour.
//
import SwiftUI

struct Paywall3DEffect: View {
    var symbols: [String]
    var symbolFont: Font
    var tint: Color
    /// View Properties
    @State private var trim: CGFloat = 0
    @State private var rotation: CGFloat = 0
    @State private var isAnimating: Bool = false
    var body: some View {
        Rectangle()
            .foregroundStyle(.clear)
            .modifier(
                Paywall3DEffectModifier(
                    symbols: symbols,
                    symbolFont: symbolFont,
                    tint: tint,
                    trim: trim,
                    rotation: rotation
                )
            )
            .task {
                guard !isAnimating else { return }
                isAnimating = true
                // 100ms grace so the GeometryReader inside the modifier has
                // measured size before `trim` starts animating; without it the
                // first frame can render at zero radius.
                try? await Task.sleep(for: .seconds(0.1))
                withAnimation(.easeInOut(duration: 1.5)) {
                    trim = 1
                }
                // Wait for trim reveal (1.5s) plus a brief settle before
                // handing off to the perpetual spin.
                try? await Task.sleep(for: .seconds(0.5))
                withAnimation(.linear(duration: 15).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}

/// Use view modifier to ensure trim/rotation properties conform to Animatable protocol
@Animatable
private struct Paywall3DEffectModifier: ViewModifier {
    @AnimatableIgnored var symbols: [String]
    @AnimatableIgnored var symbolFont: Font
    @AnimatableIgnored var tint: Color
    var trim: CGFloat = 0
    var rotation: CGFloat = 0
    // swiftlint:disable:next function_body_length
    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader {
                    let size = $0.size
                    let circleSize = min(size.width, size.height)
                    // Circumference / (2N): each symbol gets one dash + one gap
                    // of equal length, so dash length = gap length = C/(2N).
                    // `dashPhase = -dashLength / 2` shifts the pattern by half
                    // a dash so the GAP (not the dash) is centred at angle 0,
                    // which is where icon index 0 sits.
                    let dashLength = (CGFloat.pi * circleSize) / CGFloat(symbols.count * 2)
                    let dashPhase = -dashLength / 2
                    let strokeStyle = StrokeStyle(lineWidth: 3,
                                                  dash: [dashLength],
                                                  dashPhase: dashPhase)
                    ZStack {
                        Circle()
                            .trim(from: 0, to: trim)
                            .stroke(tint, style: strokeStyle)
                            .rotationEffect(.init(degrees: rotation))
                            // 62° X-axis tilt — load-bearing magic number; the
                            // icon math below uses `cos(62°)` to match this.
                            // `perspective: 0` keeps the projection orthographic;
                            // a non-zero value would scale far icons unevenly.
                            .rotation3DEffect(
                                .init(degrees: 62),
                                axis: (x: 1, y: 0, z: 0),
                                anchor: .center,
                                perspective: 0
                            )
                            // -20° Z roll — paired with each icon's `+20°` Z
                            // counter-rotation below so icons end up upright
                            // while the ring stays rolled.
                            .rotation3DEffect(
                                .init(degrees: -20),
                                axis: (x: 0, y: 0, z: 1),
                                anchor: .center,
                                perspective: 0
                            )
                        // Icons can't share the ring's `rotation3DEffect`: the X-tilt
                        // would squash their glyphs and the Z-roll would tilt the
                        // text. Instead we place each icon manually on the projected
                        // ellipse.
                        ZStack {
                            ForEach(symbols.indices, id: \.self) { index in
                                let radius = circleSize / 2
                                // Spread icons evenly around 0–360°, then add
                                // the global `rotation` so they orbit with the
                                // ring's spin instead of staying parked.
                                let angle = (CGFloat(index) / CGFloat(symbols.count)) * 360 + rotation
                                let angleInRadians = (CGFloat.pi * angle) / 180
                                // Y-projection factor: tilting the ring 62°
                                // around X squashes its vertical span by
                                // cos(62°). Multiplying `sin(θ)·r` by this
                                // factor places icons on the SAME ellipse the
                                // tilted circle traces. MUST stay in sync with
                                // the 62° on the ring's rotation3DEffect above.
                                let rotation3D = cos((62 * CGFloat.pi) / 180)
                                let xPos = cos(angleInRadians) * radius
                                let yPos = sin(angleInRadians) * radius * rotation3D

                                // Staggered reveal: each icon owns a 1/N slice
                                // of `trim` (start..<end). `scaleProgress` ramps
                                // 0→1 only while `trim` crosses that slice, so
                                // icons pop in sequentially as the stroke
                                // sweeps past them.
                                let start = CGFloat(index) / CGFloat(symbols.count)
                                let end = CGFloat(index + 1) / CGFloat(symbols.count)
                                let scaleProgress = max(min((trim - start) / (end - start), 1), 0)

                                // Per-icon rotation: + (index × 10°) gives each
                                // icon a slightly different starting tilt so the
                                // ring doesn't look like a stamped pattern.
                                let iconRotation = rotation + CGFloat(index * 10)

                                Image(systemName: symbols[index])
                                    .font(symbolFont)
                                    .foregroundStyle(tint)
                                    .shadow(color: tint.opacity(0.15), radius: 2, x: 1, y: 2)
                                    .shadow(color: tint.opacity(0.1), radius: 8, x: 4, y: 8)
                                    .scaleEffect(scaleProgress)
                                    // 2D Z-rotation is safe (just spins the glyph).
                                    .rotationEffect(.init(degrees: iconRotation))
                                    // Y-axis flip animates icons "facing camera ↔
                                    // facing away" as they orbit. perspective: 0
                                    // for the same reason as the ring.
                                    .rotation3DEffect(
                                        .init(degrees: iconRotation),
                                        axis: (x: 0, y: 1, z: 0),
                                        anchor: .center,
                                        perspective: 0
                                    )
                                    // +20° here cancels the parent ZStack's -20°
                                    // below — net Z = 0 on each icon, so glyphs
                                    // stay upright while the icon-ring as a whole
                                    // rolls to match the dashed ring.
                                    .rotationEffect(.init(degrees: 20))
                                    .offset(x: xPos, y: yPos)
                            }
                        }
                        // Roll the icon group -20° in 2D to match the dashed
                        // ring's 3D Z-roll. Plain rotationEffect (not
                        // rotation3DEffect) is intentional: 2D Z-rotation
                        // doesn't distort the glyphs.
                        .rotationEffect(.init(degrees: -20))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
    }
}

#Preview {
    let symbols: [String] = [
        "photo",
        "square.arrowtriangle.4.outward",
        "inset.filled.pano",
        "square.and.arrow.up.fill",
        "pawprint",
    ]
    Paywall3DEffect(symbols: symbols, symbolFont: .title, tint: .primary)
        .frame(height: 300)
}
