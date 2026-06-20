//
//  StickyScrollSectionHeader.swift
//  animation
//
//  Created on 6/20/26.
//
//  Learning point
//  ──────────────
//  Recreates the Apple Weather app's sticky section cards: a section's
//  header pins to the top of its card while the content scrolls beneath
//  it; once the header reaches the top it cross-fades into a compact
//  `minimizedHeader`, and as the whole card scrolls off it scales +
//  fades away.
//
//  Mechanics
//  ─────────
//    1. Each StickySection owns a named coordinate space ("SECTION") so
//       every `visualEffect` measures position relative to its OWN card,
//       not the shared scroll view — this is what lets multiple sections
//       collapse independently.
//    2. Header swap: `minY` inside the section drives a 0→1 progress that
//       fades the full header out and the minimized header in.
//    3. Content pinning: content gets `.offset(y: -minY)` so it stays
//       glued to the top edge as the card body scrolls past, with
//       `.clipped()` hiding the overflow.
//    4. mask + background both pad their bottom by the live `minY`,
//       shrinking the visible rounded card so its corners track the
//       collapse.
//    5. `compositingGroup()` + a final `visualEffect` scale/fade the
//       finished card as it exits past the cutoff.
//
//  Key APIs
//  ────────
//  • `coordinateSpace(.named("SECTION"))` + `proxy.frame(in:)` — per-card
//    geometry, the crux of independent sticky sections.
//  • `visualEffect` — all motion is GPU-side, no per-frame @State.
//  • `proxy.frame(in: .scrollView(axis:))` — offset vs the whole scroll
//    view, used for the exit scale/fade.
//  • `onGeometryChange(for: CGSize.self)` — captures header height to
//    compute the collapse cutoff.
//  • `.glassEffect(.regular, in:)` — optional Liquid Glass card fill.
//
//  How to apply
//  ────────────
//  Reach for this when you want several independently-collapsing cards
//  in one scroll view (weather, dashboards, grouped feeds). The
//  named-coordinate-space-per-section trick is what lets each card
//  animate on its own clock.
//
//  Note: `@ContentBuilder` is the project's result builder; swap to
//  `@ViewBuilder` on stock Xcode 26.
//
//  See also
//  ────────
//  • SwipeableCustomTabbar.swift — sibling iOS27 demo built on the same
//    scroll-geometry + `visualEffect` toolkit.
//
import SwiftUI

@available(iOS 26.0, *)
struct StickyScrollSectionHeaderDemo: View {
    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 12) {
                StickySection {
                    HStack(spacing: 10) {
                        Image(systemName: "cloud.fill")
                        Text("Scattered light rain from 10pm to 11 pm.")
                    }
                    .padding(.vertical, 10)
                } header: {
                    HStack {
                        Text("Highlights")
                            .fontWeight(.semibold)

                        Spacer(minLength: 0)

                        Image(systemName: "exclamationmark.bubble.fill")
                            .font(.callout)
                    }
                } minimizedHeader: {
                    HStack(spacing: 6) {
                        Image(systemName: "text.menu")
                        Text("HIGHLIGHTS")
                        Spacer(minLength: 0)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .safeAreaPadding(15)
    }
}

@available(iOS 26.0, *)
struct StickySection<Content: View, Header: View, MinimizedHeader: View>: View {
    var config: Config = .init()
    var spacing: CGFloat = 10
    @ContentBuilder var content: Content
    @ContentBuilder var header: Header
    @ContentBuilder var minimizedHeader: MinimizedHeader
    /// View Properties
    @State private var headerSize: CGSize = .zero
    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            header
                .padding([.horizontal, .top], config.sectionPadding)
                // Cross-fade, front half: fade the FULL header out as the
                // section scrolls up. Pairs with the minimizedHeader effect
                // below (opposite ramp) to morph between the two states.
                .visualEffect { content, proxy in
                    let rect = proxy.frame(in: .named("SECTION"))
                    let minY = max(rect.minY - config.sectionPadding, 0)
                    let progress = max(min(minY / config.headerFadeDistance, 1), 0)

                    return content
                        .opacity(1 - progress)
                }
                .background {
                    minimizedHeader
                        .frame(maxHeight: .infinity)
                        .offset(y: config.minimizedHeaderOffset / 2)
                        // Cross-fade, back half: fade the COMPACT header in.
                        // The extra `- headerFadeDistance` offsets the ramp so
                        // it only begins after the full header has faded out,
                        // giving a sequential swap rather than a blurry overlap.
                        .visualEffect { content, proxy in
                            let rect = proxy.frame(in: .named("SECTION"))
                            let minY = max(rect.minY - config.sectionPadding - config.headerFadeDistance, 0)
                            let progress = max(min(minY / config.headerFadeDistance, 1), 0)

                            return content
                                .opacity(progress)
                        }
                }
                .padding([.horizontal, .top], config.sectionPadding)
                .onGeometryChange(for: CGSize.self) {
                    $0.size
                } action: { newValue in
                    headerSize = newValue
                }

            content
                .padding([.horizontal, .bottom], config.sectionPadding)
                // The "sticky" pin: once the header reaches the top, slide the
                // body upward by the same amount it keeps scrolling so it
                // collapses BEHIND the held header. `.clipped()` (+ the card
                // mask) hides the body that slides out of view.
                .visualEffect { content, proxy in
                    let rect = proxy.frame(in: .named("SECTION"))
                    let scrollMinY = proxy.frame(in: .scrollView(axis: .vertical)).minY
                    let minY = max(rect.minY - scrollMinY, 0)

                    return content
                        .offset(y: -minY)
                }
                .clipped()
        }
        .mask {
            GeometryReader { proxy in
                let rect = proxy.frame(in: .named("SECTION"))
                let viewHeight = proxy.size.height
                let headerHeight = headerSize.height + config.sectionPadding
                let bottomPadding = min(max(rect.minY, 0), viewHeight - headerHeight)

                RoundedRectangle(cornerRadius: config.cornerRadius)
                    .padding(.bottom, bottomPadding)
            }
        }
        .background {
            GeometryReader { proxy in
                let rect = proxy.frame(in: .named("SECTION"))
                let viewHeight = proxy.size.height
                let headerHeight = headerSize.height + config.sectionPadding
                let bottomPadding = min(max(rect.minY, 0), viewHeight - headerHeight)

                Group {
                    if config.isGlassBackground {
                        Rectangle()
                            .fill(.clear)
                            .glassEffect(.regular, in: .rect(cornerRadius: config.cornerRadius))
                    } else {
                        RoundedRectangle(cornerRadius: config.cornerRadius)
                            .fill(config.background)
                    }
                }
                .padding(.bottom, bottomPadding)
            }
        }
        // compositingGroup flattens the whole card first so the exit effect
        // below scales/fades it as ONE unit instead of transforming each child.
        .compositingGroup()
        // Exit animation: as the collapsed card scrolls past its cutoff,
        // scale it down + fade it out (and hold it in place via the offset)
        // so it recedes instead of hard-clipping at the top edge.
        .visualEffect { content, proxy in
            let rect = proxy.frame(in: .scrollView(axis: .vertical))
            let minY = rect.minY
            let headerHeight = headerSize.height + config.sectionPadding + config.minimizedHeaderOffset
            let cutoffHeight = proxy.size.height - headerHeight
            let distance = abs(min(cutoffHeight + minY, 0))
            let progress = max(min(distance / config.fadeDistance, 1), 0)
            let scale = 1 - (progress * config.fadeScale)
            let opacity = 1 - progress
            return content
                .scaleEffect(scale, anchor: .top)
                .opacity(opacity)
                .offset(y: minY < 0 ? -minY : 0)
        }
        .coordinateSpace(.named("SECTION"))
    }

    struct Config {
        var sectionPadding: CGFloat = 15
        var cornerRadius: CGFloat = 20
        var background: AnyShapeStyle = .init(.fill.tertiary)
        var isGlassBackground: Bool = true

        var minimizedHeaderOffset: CGFloat = -10
        var headerFadeDistance: CGFloat = 15
        var fadeDistance: CGFloat = 45
        var fadeScale: CGFloat = 0.1
    }
}

@available(iOS 26.0, *)
#Preview {
    StickyScrollSectionHeaderDemo()
}
