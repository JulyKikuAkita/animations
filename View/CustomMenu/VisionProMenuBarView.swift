//
//  VisionProMenuBarView.swift
//  animation
//
//  ⚠️  REUSABLE HELPER, NOT A STANDALONE DEMO. Consumed by
//      `View/Carousel/InfiniteCarouselView.swift:108` as the
//      menu-bar overlay around the auto-scrolling carousel. Don't
//      rename or remove without updating that call site.
//
//  TODO: Stale `#Preview`
//        The `#Preview` at the bottom calls `InfiniteCarouselIOS18DemoView()`
//        — that's the consumer demo, not THIS view. While it does
//        render this view (as part of the consumer), it's confusing:
//        someone opening this file and hitting Preview won't see
//        what they expect. Either:
//          (a) Show this view directly:
//              `VisionProMenuBarView { Text("Sample") }.padding()`
//          (b) Add a comment noting the preview deliberately
//              renders the consumer to show the bar in context.
//
//  Learning point
//  ──────────────
//  Tiny generic helper that wraps any content in a Vision-Pro-style
//  translucent menu bar. Three layers conspire to produce the look:
//    1. `.thinMaterial` outline (3pt rounded stroke).
//    2. `.ultraThinMaterial` fill with an INNER shadow
//       (`.shadow(.inner(...))` on the ShapeStyle) — this is what
//       gives the bar its "frosted scoop" depth.
//    3. Two outer shadows on `compositingGroup()` — one
//       bottom-right (8/8/8) and one top-left (5/-5/-5) — for a
//       dual-light-source look that matches Apple's visionOS UI
//       language.
//  Forced `.environment(\.colorScheme, .light)` on the background
//  so the materials read correctly even in dark-mode hosts.
//
//  Generic over `Content: View` — drop any SwiftUI view inside;
//  the helper measures it via `onGeometryChange` (the size is
//  captured but only the wrapper consumes it; useful as a hook for
//  future enhancements).
//
//  Key APIs
//  ────────
//  • `.shadow(.inner(color:radius:))` on a `ShapeStyle` — iOS 17+.
//    This is the load-bearing trick; vanilla `.shadow(_:)` doesn't
//    do inner shadows on a fill.
//  • `.compositingGroup()` — required so the outer shadows apply
//    to the COMPOSITED stack (stroke + fill + content) rather than
//    each layer separately.
//  • `.environment(\.colorScheme, .light)` — pin the background to
//    light mode so material translucency is consistent.
//
//  How to apply
//  ────────────
//  Wrap any toolbar / chip group / bottom-bar in this helper:
//  `VisionProMenuBarView(cornerRadius: 30) { contents }`.
//  The corner radius is the only knob; everything else is opinionated
//  (and intentionally so — the look is the point).
//
//  See also
//  ────────
//  • View/Carousel/InfiniteCarouselView.swift — the consumer.
//  • View/CustomMenu/CustomSideMenu+iOS26.swift — different vision
//    of "premium menu chrome" using iOS 26 `ConcentricRectangle`.
//
import SwiftUI

struct VisionProMenuBarView<Content: View>: View {
    var cornerRadius: CGFloat = 30
    @ViewBuilder var content: Content
    /// View Properties
    @State private var viewSize: CGSize = .zero

    var body: some View {
        content
            .clipShape(.rect(cornerRadius: cornerRadius, style: .continuous))
            .contentShape(.rect(cornerRadius: cornerRadius, style: .continuous))
            .background {
                backgroundView()
            }
            .compositingGroup()
            .shadow(color: .black.opacity(0.15), radius: 8, x: 8, y: 8)
            .shadow(color: .black.opacity(0.1), radius: 5, x: -5, y: -5)
            .onGeometryChange(for: CGSize.self) {
                $0.size
            } action: { newValue in
                viewSize = newValue
            }
    }

    private func backgroundView() -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(.thinMaterial, style: .init(lineWidth: 3, lineCap: .round, lineJoin: .round))

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial.shadow(.inner(color: .black.opacity(0.2), radius: 10)))
        }
        .compositingGroup()
        .environment(\.colorScheme, .light)
    }
}

#Preview {
    InfiniteCarouselIOS18DemoView()
}
