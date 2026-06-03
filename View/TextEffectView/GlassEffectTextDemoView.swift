//
//  GlassEffectTextDemoView.swift
//  animation
//
//  Created on 11/20/25.
//
//  Learning point
//  ──────────────
//  Two iOS 26 tricks that turn a `Text` into something the system can
//  apply effects to:
//
//    Example1 — Glass Effect Text
//    ────────────────────────────
//    Use the literal letterforms of "Budapest" as the SHAPE for
//    `glassEffect(.clear, in: textShape)`. The text becomes a
//    refractive glass cutout over a background photo — drag a grabber
//    to scale it. The hidden `Text` is kept (`.opacity(0)`) so layout,
//    accessibility, and font scaling all work as if it were rendered
//    normally.
//
//    Example2 — Writing Effect
//    ─────────────────────────
//    Convert text to a `Path` (via `TextToShape: Shape`), then
//    `.trim(from:to:)` + `.stroke()` it. Animating `to: 0 → 1` traces
//    the strokes like handwriting. Crucial gotcha: works on a STROKED
//    path, not a filled one — fills can't be partial.
//
//  How `TextToShape` works
//  ───────────────────────
//  `font.drawGlyphs(value)` (a project helper on `UIFont`) yields
//  per-glyph `CGPath`s with their pen-position offsets. Each glyph is
//  flipped vertically (`.scaledBy(x: 1, y: -1)`) because Core Text uses
//  Y-up coordinates while SwiftUI/CG uses Y-down. After accumulation,
//  the entire path is centred to its bounding rect. `nonisolated`
//  marks the function so `Shape.path(in:)` can be called from any
//  actor context.
//
//  Key APIs
//  ────────
//  • `Glass.clear` / `.tint(...)` + `.glassEffect(_:in:)` (iOS 26) —
//    arbitrary `Shape` becomes the lensing region.
//  • `Shape.trim(from:to:)` — animatable trimming for stroke-on
//    "writing" reveals.
//  • `UIFont.drawGlyphs(_:_:)` (project helper) — extract per-glyph
//    paths from any UIFont, custom or system.
//  • `Path.boundingRect` + `CGAffineTransform(translationX:y:)` —
//    centre the assembled glyph path within the host rect.
//
//  How to apply
//  ────────────
//  • Use `GlassEffectText` for hero typography over photos / video on
//    iOS 26 (with a `fallbackColor` for older systems).
//  • Use `TextToShape` whenever you need text as a `Shape` — masking,
//    stroking, morphing between shapes, animating along the path.
//
//  See also
//  ────────
//  • PixellateTextView.swift — sister demo using `TextRenderer` +
//    Metal shader for per-character effects.
//
import SwiftUI

struct GlassEffectTextDemoView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("Glass Effect Demo") {
                    Example1()
                }

                NavigationLink("Writing Effect Demo") {
                    Example2()
                }
            }
            .navigationTitle("Text to Shape")
        }
    }
}

private struct Example1: View {
    @State private var progressSlider: CGFloat = 0
    @State private var lastStoredValue: CGFloat = 0

    var body: some View {
        ZStack {
            let backgroundShape = RoundedRectangle(cornerRadius: 15)
                .stroke(lineWidth: 3)

            let grabberShape = Circle()
                .trim(from: 0.28, to: 0.5)
                .stroke(style: .init(lineWidth: 18, lineCap: .round, lineJoin: .round))

            Rectangle()
                .foregroundStyle(.clear)
                .overlay {
                    Image(.IMG_0207)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
                .ignoresSafeArea()

            GlassEffectText(text: "Budapest",
                            font: .systemFont(ofSize: 100 + progressSlider,
                                              weight: .bold,
                                              width: .compressed),
                            fallbackColor: .white)
                .frame(maxWidth: .infinity)
                .overlay {
                    ZStack {
                        /// Drawing background border
                        Group {
                            if #available(iOS 26, *) {
                                backgroundShape
                                    .fill(.clear)
                                    .glassEffect(.clear, in: backgroundShape)
                            } else {
                                backgroundShape
                                    .fill(.white)
                            }
                        }

                        /// Drawing background shape
                        Group {
                            if #available(iOS 26, *) {
                                grabberShape
                                    .fill(.clear)
                                    .glassEffect(.clear, in: grabberShape)
                            } else {
                                grabberShape
                                    .fill(.white)
                            }
                        }
                        .frame(width: 50, height: 50)
                        .contentShape(.rect)
                        .scaleEffect(x: -1)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                        .gesture(dragGesture)
                    }
                }
                .padding(.horizontal, 15)
                .padding(.top, 10)
                .frame(maxHeight: .infinity, alignment: .top)
        }
    }

    var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                progressSlider = max(min(value.translation.height + lastStoredValue, 100), 0)
            }.onEnded { _ in
                lastStoredValue = progressSlider
            }
    }
}

/// Effect only apply to stroked path not Filled Path
private struct Example2: View {
    @State private var animated: Bool = false
    var body: some View {
        List {
            let textShape = TextToShape(value: "Budapest", font: textFont)
            Section("Demo") {
                textShape
                    .trim(from: 0, to: animated ? 1 : 0)
                    .stroke(lineWidth: 4)
                    .frame(height: 100)
            }
            Button("Animate Text") {
                withAnimation(.easeInOut(duration: 5)) {
                    animated.toggle()
                }
            }
        }
        .navigationTitle("Writing Effect")
    }

    var textFont: UIFont {
        if let customFont = UIFont(name: "Bradley Hand", size: 60) { return customFont }
        return .systemFont(ofSize: 40, weight: .bold)
    }
}

/// Tip: the layout-preserving glass-text recipe.
/// • Render an INVISIBLE `Text` (`.opacity(0)`) so SwiftUI still computes
///   correct intrinsic size, accessibility label, and Dynamic Type.
/// • Draw the visible glass effect via `.glassEffect(... in: textShape)`,
///   where `textShape` is the `TextToShape` of the same string.
/// • On pre-iOS 26 systems, fall back to ordinary tinted `Text` —
///   callers don't need to branch.
struct GlassEffectText: View {
    var text: String
    var font: UIFont
    var fallbackColor: Color = .primary
    var isClear: Bool = true
    var glassTint: Color = .clear
    var body: some View {
        let textShape = TextToShape(value: text, font: font)
        if #available(iOS 26.0, *) {
            Text(text)
                .font(Font(font))
                .opacity(0)
                .glassEffect((isClear ? Glass.clear : Glass.regular).tint(glassTint), in: textShape)
        } else {
            Text(text)
                .font(Font(font))
                .foregroundStyle(fallbackColor)
        }
    }
}

/// Tip: text → `Path` conversion.
/// `font.drawGlyphs(_:_:)` (a project extension on `UIFont`) walks each
/// glyph in `value` and yields a `(position, CGPath)` pair. Steps:
///   1. Translate to glyph's pen position.
///   2. Flip Y axis — Core Text emits paths in mathematician coords
///      (Y-up); SwiftUI/CoreGraphics expect Y-down. Without `.scaledBy(x: 1, y: -1)`
///      every letter renders upside-down.
///   3. Append to the assembled path.
///   4. Re-centre the assembled path to `rect.center` so the shape sits
///      correctly inside whatever host frame `path(in:)` is given.
/// Marked `nonisolated` so `Shape.path(in:)` can run off the main actor
/// (Shape evaluation may happen during layout passes outside @MainActor).
struct TextToShape: Shape {
    var value: String
    var font: UIFont
    nonisolated func path(in rect: CGRect) -> Path {
        var path = Path()
        font.drawGlyphs(value) { position, glyphPath in
            let transform = CGAffineTransform(translationX: position.x, y: position.y)
                .scaledBy(x: 1, y: -1)
            let newPath = Path(glyphPath).applying(transform)
            /// Adding it to the main path
            path.addPath(newPath)
        }

        /// centering to the current bounds
        let bounds = path.boundingRect
        let offsetX = rect.midX - bounds.midX
        let offsetY = rect.midY - bounds.midY
        let centerTransform = CGAffineTransform(translationX: offsetX, y: offsetY)
        return path.applying(centerTransform)
    }
}

#Preview {
    GlassEffectTextDemoView()
}
