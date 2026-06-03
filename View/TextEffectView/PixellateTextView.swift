//
//  PixellateTextView.swift
//  animation
//
//  Learning point
//  ──────────────
//  Reveal an "API key" inline within a longer paragraph using iOS 18's
//  `TextRenderer` protocol — apply pixellate / blur / disintegrate
//  effects ONLY to characters tagged with a custom `TextAttribute`,
//  while leaving the rest of the text rendered normally.
//
//  How it fits together
//  ────────────────────
//    1. **`APIKeyAttribute: TextAttribute`** — empty marker type.
//       Attached to a sub-`Text` via `.customAttribute(APIKeyAttribute())`.
//       The attribute travels with the text run through layout.
//    2. **`RevealRenderer: TextRenderer`** (defined in a sibling file) —
//       receives the laid-out text via a `Layout` parameter; iterates
//       lines/runs/glyphs; applies the chosen effect ONLY to runs
//       carrying `APIKeyAttribute`.
//    3. **`Pixellate.metal` (`[[stitchable]] float2 pixellate(...)`)** —
//       a tiny Metal shader registered with SwiftUI's runtime via
//       `[[stitchable]]` (iOS 17+). The shader rounds incoming pixel
//       positions to a grid, producing the chunky-pixel look.
//
//  What is `[[stitchable]]`?
//  ─────────────────────────
//  An attribute that lets SwiftUI compose your shader into its own
//  rendering pipeline at runtime — no `MTLRenderPipelineState`
//  ceremony, no manual draw calls. Reference the shader from Swift via
//  `ShaderLibrary.default[dynamicMember:]` / `Shader(function:..., arguments:)`.
//  Trade-off: limited to position/effect shaders that fit SwiftUI's
//  prescribed signatures; full control still requires a `MetalView`.
//
//  Why a `TextAttribute` instead of just rendering pieces separately?
//  ─────────────────────────────────────────────────────────────────
//  Wrapping the key in its own `Text` and concatenating with `+`
//  *would* let you apply a shader, but you'd lose multi-line layout —
//  the renderer wouldn't know how to break the line correctly between
//  the regular and effected text. `TextAttribute` keeps everything in
//  one paragraph; the renderer just decides per-run how to draw.
//
//  Key APIs
//  ────────
//  • `TextAttribute` (iOS 18) — marker protocol; attach to `Text` via
//    `.customAttribute(...)`.
//  • `TextRenderer` (iOS 18) — fine-grained text painting protocol,
//    walked per line/run/glyph.
//  • `.textRenderer(_:)` — install your renderer onto a Text container.
//  • `[[stitchable]]` Metal attribute — register a shader with SwiftUI.
//  • `Path`/`GraphicsContext` filters (the `RevealRenderer` uses these
//    in its `.blur` mode) — alternative to a Metal shader.
//
//  How to apply
//  ────────────
//  Use this whenever you want different visual effects on different
//  spans of the SAME paragraph: redacted text, syntax-highlighting
//  with effects, hyperlink emphasis, error highlighting. The
//  attribute-marker pattern generalises far beyond reveal effects.
//
//  See also
//  ────────
//  • Pixellate.metal — the shader function itself.
//  • GlassEffectTextDemoView.swift — sister demo using
//    `Shape`-based text instead of a `TextRenderer`.
//

import SwiftUI

@available(iOS 18.0, *)
struct PixellateTextView: View {
    @State private var reveal: Bool = false
    @State private var type: RevealRenderer.RevealType = .blur
    @State private var revealProgress: CGFloat = 0

    var body: some View {
        // NavigationStack introduce buggy behavior with text effect at the time of writing
        VStack {
            Picker("", selection: $type) {
                ForEach(RevealRenderer.RevealType.allCases, id: \.rawValue) { type in
                    Text(type.rawValue)
                        .tag(type)
                }
            }
            .pickerStyle(.segmented)

            let apiKey = Text("qazwsx123edcrfv")
                .fontWeight(.semibold)
                .foregroundStyle(Color.primary)
                .customAttribute(APIKeyAttribute())

            Text("Your API Key is \(apiKey).\n Don't share it.")
                .font(.largeTitle)
                .fontDesign(.rounded)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .foregroundColor(.gray)
                .textRenderer(
                    RevealRenderer(type: type, progress: revealProgress)
                ) // count as a new line
                .padding(.vertical, 20)

            Button {
                reveal.toggle()
                withAnimation(.smooth) {
                    revealProgress = reveal ? 1 : 0
                }
            } label: {
                Text(reveal ? "Hide Key" : "Reveal Key")
                    .padding(.horizontal, 25)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .tint(.black)

            Spacer(minLength: 0)
        }
        .padding(15)
        .navigationTitle("Text Rendered")
    }
}

#Preview {
    if #available(iOS 18.0, *) {
        PixellateTextView()
    } else {
        // Fallback on earlier versions
    }
}

/// Tip: marker `TextAttribute`s carry no data themselves — the type
/// IS the signal. Inside a `TextRenderer`, ask each run
/// `run.contains(APIKeyAttribute.self)` to decide whether to apply the
/// effect. To carry parameters (e.g. a per-key blur radius), add stored
/// properties to the struct and read them off the run's attribute set.
struct APIKeyAttribute: TextAttribute {}
