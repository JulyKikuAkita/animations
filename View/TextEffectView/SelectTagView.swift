//
//  SelectTagView.swift
//  animation
//
//  Learning point
//  ──────────────
//  Two-pane tag picker: a horizontal "selected" strip on top, and a
//  flow-wrapped "available" pool below. Tapping a tag in either pane
//  moves it to the OTHER pane — and the move is animated as a single
//  view *travelling* across panes via `matchedGeometryEffect`, not a
//  remove-here / insert-there fade.
//
//  Why `matchedGeometryEffect` is the whole trick
//  ──────────────────────────────────────────────
//  Without it, SwiftUI sees the tag disappear from one `ForEach` and
//  appear in another — two unrelated views. With it, both renderings
//  share the same `id: tag` in the same `Namespace`, so SwiftUI
//  interpolates the geometry between them. The visual result is one
//  capsule that flies from the pool to the selected strip.
//
//  Layout pieces
//  ─────────────
//  • **Top strip** — `ScrollView(.horizontal)` showing `selectedTags`
//    as pink capsules with a `checkmark`.
//  • **Bottom pool** — uses `TagLayout` (project-local custom Layout)
//    to wrap chips into rows. Filtered to exclude already-selected tags
//    so each capsule appears in only one pane at a time.
//  • **Bottom button** — disabled until 3+ tags selected, hard-fades to
//    50% opacity to telegraph the gate.
//
//  Z-index discipline
//  ──────────────────
//  Three sibling stacks at known `zIndex` values: top strip = 1,
//  pool = 0, action button = 2. Required because animated tags can
//  briefly overshoot their pane during the matched-geometry transit;
//  explicit zIndex prevents them from rendering ABOVE the action
//  button or BEHIND the parent backgrounds.
//
//  Key APIs
//  ────────
//  • `@Namespace` + `matchedGeometryEffect(id:in:)` — the matched-move
//    primitive.
//  • `withAnimation(.snappy) { selectedTags.insert(...) }` — wraps the
//    state change so the matched move animates.
//  • `TagLayout` (project-local) — flow-layout primitive used here.
//  • `.scrollClipDisabled(true)` (iOS 17+) — let the moving capsule
//    visually leave the pool's scroll bounds during transit.
//
//  How to apply
//  ────────────
//  Use this pattern any time an item visibly moves between containers:
//  cart vs catalogue, draft vs published, inbox vs archive. The
//  matched-geometry trick + `zIndex` discipline + `withAnimation`
//  wrapper is the reusable recipe.
//
//  See also
//  ────────
//  • DynamicTagWidthView.swift — flow layout via `Group(subviews:)`
//    + `ContainerValues`, no selection state.
//  • TagFieldView.swift — interactive tag entry with focus + delete.
//

import SwiftUI

struct SelectTagViewDemo: View {
    /// View properties
    /// Sample tags
    @State private var tags: [String] = [
        "Berserk", "Hunter", "One Piece", "Chainsaw Man", "Tokyo Ghoul",
        "Solo Leveling", "Naruto", "Monster", "Vagabond", "SpyFamily",
        "One Punch-Man", "Hero Academia", "Jujutsu Kaisen", "Fullmetal Alchemist",
        "Pandora Hearts", "Bleach", "Gantz", "Frieren",
    ]

    /// Selection
    @State private var selectedTags: [String] = []
    /// Adding matched geometry effect
    @Namespace private var animation
    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    // Tip: same `id: tag` and same `Namespace` are used in
                    // both ForEach loops — that's how SwiftUI knows these
                    // two views are the SAME logical capsule moving between
                    // panes. Without the `withAnimation` wrapper on the
                    // state mutation, the move snaps instantly instead.
                    ForEach(selectedTags, id: \.self) { tag in
                        tagView(tag, .pink, "checkmark")
                            .matchedGeometryEffect(id: tag, in: animation)
                            .onTapGesture {
                                withAnimation(.snappy) {
                                    selectedTags.removeAll(where: { $0 == tag })
                                }
                            }
                    }
                }
                .padding(.horizontal, 15)
                .frame(height: 35)
                .padding(.vertical, 15)
            }
            .overlay(content: {
                if selectedTags.isEmpty {
                    Text("Select more than 3 Tags")
                        .font(.callout)
                        .foregroundStyle(.gray)
                }
            })
            .background(.white)
            .zIndex(1)

            ScrollView(.vertical) {
                TagLayout(spacing: 10) {
                    ForEach(tags.filter { !selectedTags.contains($0) }, id: \.self) { tag in
                        tagView(tag, .blue, "plus")
                            .matchedGeometryEffect(id: tag, in: animation)
                            .onTapGesture {
                                /// Adding to Selected Tag list
                                withAnimation(.snappy) {
                                    selectedTags.insert(tag, at: 0)
                                }
                            }
                    }
                }
                .padding(15)
            }
            .scrollClipDisabled(true)
            .scrollIndicators(.hidden)
            .background(.black.opacity(0.05))
            .zIndex(0)

            ZStack {
                Button(action: {
                    selectedTags.removeAll()
                }, label: {
                    Text("Reset")
                        .fontWeight(.semibold)
                        .padding(.vertical, 15)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .background {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.pink.gradient)
                        }
                })
                /// Disabling until 3 more tags selected
                .disabled(selectedTags.count <= 3)
                .opacity(selectedTags.count <= 3 ? 0.5 : 1)
                .padding()
            }
            .background(.white)
            .zIndex(2)
        }
        .preferredColorScheme(.light)
    }

    /// Tag view
    @ViewBuilder
    func tagView(_ tag: String, _ color: Color, _ icon: String) -> some View {
        HStack(spacing: 10) {
            Text(tag)
                .font(.callout)
                .fontWeight(.semibold)

            Image(systemName: icon)
        }
        .frame(height: 35)
        .foregroundStyle(.white)
        .padding(.horizontal, 15)
        .background {
            Capsule()
                .fill(color)
        }
    }
}

#Preview {
    SelectTagViewDemo()
}
