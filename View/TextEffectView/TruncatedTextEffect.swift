//
//  TruncatedTextEffect.swift
//  animation
//
//  Created on 12/16/25.
//
//  Learning point
//  ──────────────
//  Demo wrapper for the project's `truncationEffect(length:isEnabled:animation:)`
//  modifier. Tap to expand/collapse a long paragraph: when collapsed,
//  text past `length` is truncated; the transition between full and
//  truncated states animates smoothly rather than a hard cut.
//
//  Where the actual logic lives
//  ────────────────────────────
//  This file is just the demo harness — the `.truncationEffect(...)`
//  modifier is defined elsewhere in the project (search for
//  `truncationEffect` to find the implementation). Typically built on
//  top of an `Animatable` modifier that interpolates a character-count
//  cap, or a `TextRenderer` that animates per-glyph opacity.
//
//  Why animated truncation matters
//  ───────────────────────────────
//  The default `lineLimit(_:)` change in SwiftUI snaps instantly, even
//  inside `withAnimation`. Smooth expand/collapse needs either:
//   • Animatable property (e.g. revealed character count or visible
//     line count) — see `[[FlipClockTextEffectView]]` for the same
//     `Animatable` pattern applied to digit flips.
//   • Or a `TextRenderer` that interpolates per-glyph alpha.
//
//  Key APIs
//  ────────
//  • `.truncationEffect(length:isEnabled:animation:)` — project-local
//    modifier; see its definition for which approach it uses.
//  • `withAnimation { isEnabled.toggle() }` happens implicitly inside
//    the modifier's `animation:` parameter.
//
//  How to apply
//  ────────────
//  Useful for "Read more" / "Show less" toggles, comments threads,
//  product descriptions, and any content where a hard layout snap
//  would feel jarring.
//
//  See also
//  ────────
//  • FlipClockTextEffectView.swift — `Animatable` modifier pattern.
//  • PixellateTextView.swift — `TextRenderer` pattern for per-glyph
//    effects.
//

import SwiftUI

struct TruncatedTextEffectDemoView: View {
    @State private var isEnabled: Bool = false
    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                VStack {
                    Text(fullDummyDescription)
                        .truncationEffect(
                            length: 10,
                            isEnabled: isEnabled,
                            animation: .smooth(duration: 0.3, extraBounce: 0)
                        )
                        .onTapGesture {
                            isEnabled.toggle()
                        }
                }
                .padding(15)
            }
            .navigationTitle("Truncated Text Effect")
        }
    }
}

#Preview {
    TruncatedTextEffectDemoView()
}
