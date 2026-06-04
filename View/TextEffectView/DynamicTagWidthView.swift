//
//  DynamicTagWidthView.swift
//  animation
//
//  Learning point
//  ──────────────
//  Width-aware "pill" / "chip" wrapping using iOS 18's
//  `Group(subviews:)` + `@Entry` `ContainerValues`. Each chip measures
//  its own intrinsic width and stashes it into a custom container value;
//  the parent then chunks subviews into rows that fit `maxWidth`.
//
//  Why not just `FlowLayout` / a custom `Layout`?
//  ──────────────────────────────────────────────
//  A `Layout` recomputes sizes on every layout pass and is hard to
//  customise with per-child styling outside the layout function. The
//  `Group(subviews:) + chunkByWidth` pattern uses ordinary SwiftUI views
//  with an `HStack`/`VStack`, so each row keeps standard alignment,
//  spacing, and animation behaviour for free.
//
//  Key APIs
//  ────────
//  • `Group(subviews: content) { collection in ... }` (iOS 18) — gives
//    the parent a typed `SubviewsCollection` of its children, so it can
//    inspect them as data, not opaque views.
//  • `@Entry` on `ContainerValues` — iOS 18 sugar for declaring a
//    container-value key without a `PreferenceKey`-style boilerplate.
//  • `subview.containerValues.viewWidth` — read the value each child
//    published via `.containerValue(\.viewWidth, ...)`.
//  • `String.size(_:UIFont)` — pre-render text-width measurement using
//    `NSAttributedString` attributes; lighter than rendering off-screen.
//
//  How to apply
//  ────────────
//  Use whenever you need data-driven layout decisions on heterogeneous
//  children (filter chips, breadcrumbs, autocomplete suggestions). Same
//  pattern works for height-, priority-, or category-based grouping —
//  just publish a different `@Entry` value.
//
//  See also
//  ────────
//  • SelectTagView.swift — uses `TagLayout` (a `Layout` conformer)
//    instead; compare to see when each approach wins.
//  • TagFieldView.swift — interactive tag input on top of `TagLayout`.
//
import SwiftUI

struct DynamicTagWidthDemoView: View {
    var body: some View {
        DynamicTagWidthView()
    }
}

struct DynamicTagWidthView: View {
    var body: some View {
        NavigationStack {
            VStack {
                ChipsView(maxWidth: 230) {
                    ForEach(mockChips) { chip in
                        let viewWidth = chip.name.size(.preferredFont(forTextStyle: .body)).width + 20
                        Text(chip.name)
                            .font(.body)
                            .foregroundStyle(.white)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 10)
                            .background(.brown.gradient, in: .capsule)
                            .containerValue(\.viewWidth, viewWidth)
                    }
                }
                .frame(width: 300)
                .padding(15)
                .background(.primary.opacity(0.06), in: .rect(cornerRadius: 10))
            }
            .padding(15)
            .navigationTitle("Pills")
        }
    }
}

struct ChipsView<Content: View>: View {
    var maxWidth: CGFloat // pill layout will be auto-adjusted based on width
    @ViewBuilder var content: Content
    var body: some View {
        Group(subviews: content) { collection in
            let chunkedCollection = collection.chunkByWidth(maxWidth)

            VStack(alignment: .center, spacing: 10) {
                ForEach(chunkedCollection.indices, id: \.self) { index in
                    HStack(spacing: 10) {
                        ForEach(chunkedCollection[index]) { subview in
//                            let viewWidth = subview.containerValues.viewWidth
//                            let _ = print(viewWidth)
                            subview
                        }
                    }
                }
            }
        }
    }
}

/// Tip: greedy first-fit row packer.
/// Walks subviews in declaration order; each chip's `viewWidth` is the
/// pre-measured width (set via `.containerValue(\.viewWidth, ...)` at the
/// call site). When the running row exceeds `containerWidth`, flush the
/// row and start a new one. O(n), no backtracking — same algorithm CSS
/// flexbox uses for `flex-wrap`.
private extension SubviewsCollection {
    func chunkByWidth(_ containerWidth: CGFloat) -> [[Subview]] {
        var row: [Subview] = []
        var rowWidth: CGFloat = 0
        var rows: [[Subview]] = []
        let spacing: CGFloat = 10

        for subview in self {
            let viewWidth = subview.containerValues.viewWidth + spacing
            rowWidth += viewWidth
            if rowWidth < containerWidth {
                row.append(subview)
            } else {
                rows.append(row)
                row = [subview]
                rowWidth = viewWidth
            }
        }

        if !row.isEmpty {
            rows.append(row)
        }
        return rows
    }

    func chunked(_ size: Int) -> [[Subview]] {
        stride(from: 0, through: count, by: size).map { index in
            Array(self[index ..< Swift.min(index + size, count)])
        }
    }
}

struct Chip: Identifiable {
    var id: String = UUID().uuidString
    var name: String
}

var mockChips: [Chip] = tagNames.map { Chip(name: $0) }

private var tagNames: [String] = [
    "Berserk", "Hunter", "One Piece", "Chainsaw Man", "Tokyo Ghoul", "Solo Leveling",
    "Naruto", "Monster", "Vagabond", "SpyFamily", "One Punch-Man", "Hero Academia",
    "Jujutsu Kaisen", "Fullmetal Alchemist", "Pandora Hearts", "Bleach", "Gantz", "Frieren",
]

/// get the size of text view based on the font type
extension String {
    func size(_ font: UIFont) -> CGSize {
        let attributes = [NSAttributedString.Key.font: font]
        return size(withAttributes: attributes)
    }
}

/// Tip: `@Entry` is iOS 18's one-liner replacement for the old
/// `EnvironmentKey` / `PreferenceKey` boilerplate.
/// Before iOS 18 you had to define a key struct + extension on
/// `ContainerValues` manually; `@Entry` synthesises both.
/// Children publish via `.containerValue(\.viewWidth, value)`; parent
/// reads via `subview.containerValues.viewWidth`.
extension ContainerValues {
    @Entry var viewWidth: CGFloat = 0
}

#Preview {
    DynamicTagWidthDemoView()
}
