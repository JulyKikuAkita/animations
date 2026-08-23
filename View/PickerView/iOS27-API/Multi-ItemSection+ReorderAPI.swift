//
//  Multi-ItemSection+ReorderAPI.swift
//  animation
//
//  Created on 8/19/26.
//
//  Learning point
//  ──────────────
//  Two grid sections that exchange items by drag. iOS 27 splits reordering
//  across three modifiers, and the demo is really about where each one's
//  responsibility ends:
//    1. `.reorderable(collectionID:)` marks a `ForEach` as movable and names
//       the collection its rows belong to.
//    2. `.reorderContainer(for:in:)` scopes the interaction and hands back a
//       `ReorderDifference` for the app to apply.
//    3. `.dragContainer(for:)` turns dragged IDs into transferable models,
//       which is what a custom drop destination needs.
//
//  The gap worth remembering: a `ReorderDifference` destination is either
//  `.before(itemID)` or `.end` of a collection SwiftUI already knows about, so
//  an *empty* section offers nothing to aim at and never becomes a reorder
//  destination. That is why the empty state carries its own `dropDestination`
//  and its own insertion path.
//
//  Mechanics
//  ─────────
//    1. `sections` is the only source of truth. `AppSectionView` receives a
//       value copy plus a callback, so both drop paths mutate in the parent.
//    2. Reorder path: remove the sources from whichever section holds them,
//       then compute the landing index *against the already-mutated array*,
//       then insert.
//    3. Empty-section path: the same removal, then a plain append — there is no
//       position to compute.
//    4. Multi-select: `.dragContainerSelection` publishes the selection so one
//       drag carries every selected item; `.dragContainer` maps those IDs back
//       to models.
//    5. `.onDropSessionUpdated` drives only the dashed affordance, never data.
//
//  Key APIs
//  ────────
//  • `.reorderable(collectionID:)` — a `DynamicViewContent` modifier, so it
//    belongs on the `ForEach` itself, not on the enclosing grid.
//  • `.reorderContainer(for:in:)` — `in:` is the *collection ID type*, which
//    has to match what `reorderable(collectionID:)` passes.
//  • `ReorderDifference` — `sources: [ItemID]` plus a destination of
//    `collectionID` and `.before(ItemID)` / `.end`. IDs only; model lookup is
//    the app's job.
//  • `.dragContainer(for:)` — closure receives `[Item.ID]`, returns `[Item]`.
//  • `.dragContainerSelection(_:)` — takes an `@autoclosure`, so the array is
//    re-read when a drag begins rather than snapshotted at view-build time.
//  • `.onDropSessionUpdated` — `DropSession.Phase` is
//    `.entering` / `.active` / `.exiting` / `.ended(_)` / `.dataTransferCompleted`.
//  • `ProxyRepresentation(exporting: \.id)` — send identity, not the model.
//  • `.contentShape(.dragPreview, .rect(cornerRadius:))` — shape the lifted
//    preview independently of the hit-test shape.
//
//  Trade-offs to stay clear-eyed about
//  ───────────────────────────────────
//  • The two paths duplicate the "remove from the owning section" loop. They
//    have to stay in step; only the insertion half legitimately differs.
//  • `contains(ids:)` is an `allSatisfy`, so a selection spanning *both*
//    sections matches neither and the drag silently carries nothing. This
//    demo is correct for single-section selections only.
//  • The destination is typed on `AppItem.ID`, i.e. `String`, which is what
//    lets the proxy representation land — but it also means any dragged text
//    lights up the affordance.
//
//  How to apply
//  ────────────
//  Reach for this when sections can be emptied and refilled: the reorder API
//  covers every populated case, and the custom destination is the minimum
//  needed to make "drag into nothing" work. Sections that can never be empty
//  do not need the second path at all.
//
// minimal version required: xcdoe27 beta5
// see https://developer.apple.com/documentation/swiftui/view/ondropsessionupdated%28_%3A%29
//
import SwiftUI

@available(iOS 27.0, *)
struct ReorderableItemDemo: View {
    // The source of truth: each section owns its ordered collection of apps.
    @State private var sections: [AppSection] = [
        .init(id: "Listed Apps", apps: [
            .init(name: "Kiku", image: "nanachiPaint"),
            .init(name: "JCB", image: "JCB"),
            .init(name: "Tesla", image: "Tesla icon"),
            .init(name: "Mr Fox", image: "fox"),
            .init(name: "Owl", image: "owl"),
            .init(name: "Sloth", image: "sloth"),
        ]),
        .init(id: "Removed Apps", apps: []),
    ]
    // Editing mode controls whether taps build a multi-item drag selection.
    @State private var isMultipleSelectionEnabled: Bool = false
    // One set spans both sections, so a selection can straddle them — which the
    // section-owning lookups below cannot resolve. See the header trade-offs.
    @State private var multipleSelection: Set<AppItem.ID> = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Empty sections report custom drops back to the parent, which owns `sections`.
                ForEach(sections) { section in
                    AppSectionView(
                        section: section,
                        isMultipleSelectionEnabled: isMultipleSelectionEnabled,
                        multipleSelection: $multipleSelection
                    ) { ids in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            insertNewItem(section, ids: ids)
                        }
                    }
                }
            }
            // One reorder scope spans all sections. The difference contains source IDs
            // plus a destination section and position.
            .reorderContainer(for: AppItem.self, in: AppSection.ID.self) { difference in
                let sourceIDs = difference.sources
                let destination = difference.destination.position
                let sectionID = difference.destination.collectionID

                // Remove first, then calculate the destination against the updated array.
                // This preserves order when several selected items move together.
                var sourceItems: [AppItem] = []
                for (index, section) in sections.enumerated() {
                    if section.apps.contains(ids: sourceIDs) {
                        sourceItems = section.apps.filtered(by: sourceIDs)
                        sections[index].apps.remove(ids: sourceIDs)
                    }
                }
                guard let landingSectionIndex = sections.firstIndex(where: { $0.id == sectionID }),
                      !sourceItems.isEmpty else { return }

                // A destination is either before an existing item or at the collection end.
                // Computed, not stored, and deliberately declared *after* the removal above:
                // it reads `sections` at the point of use, so the index already accounts for
                // the extracted items. Hoisting this over the loop would leave it stale for
                // any move within one section.
                var destinationIndex: Int {
                    let items = sections[landingSectionIndex].apps
                    switch destination {
                    case let .before(itemID):
                        return items.firstIndex(where: { $0.id == itemID }) ?? items.endIndex
                    case .end:
                        return items.endIndex
                    }
                }
                sections[landingSectionIndex].apps.insert(contentsOf: sourceItems, at: destinationIndex)
                multipleSelection.removeAll()
            }
            // Supplies dragged models for custom destinations, including empty sections.
            // The container hands over IDs only, so the models are looked up here.
            .dragContainer(for: AppItem.self) { draggedItemIDs in
                var draggedItems: [AppItem] = []
                for section in sections {
                    if section.apps.contains(ids: draggedItemIDs) {
                        draggedItems = section.apps.filtered(by: draggedItemIDs)
                    }
                }
                let selectIDs = Array(multipleSelection)
                // Starting a drag outside the active selection resets that selection.
                // Read the containment in that direction: the payload contains every
                // selected ID exactly when the gesture picked up the selection itself.
                if !(isMultipleSelectionEnabled && draggedItems.contains(ids: selectIDs)) {
                    /// cleanup selected IDs
                    multipleSelection.removeAll()
                }
                return draggedItems
            }
            // Passes the current selection to a multi-item drag session. The parameter is an
            // autoclosure, so this is a live read at drag time, not a stale copy from the
            // last body evaluation.
            .dragContainerSelection(Array(multipleSelection))
            .padding(15)
            .background(.gray.opacity(0.1))
            .navigationTitle("Reorderable")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isMultipleSelectionEnabled ? "Done" : "Edit") {
                        isMultipleSelectionEnabled.toggle()
                        multipleSelection.removeAll()
                    }
                }
            }
        }
    }

    /// Moves apps into an empty section, where reordering has no item from which
    /// to calculate a precise insertion position.
    ///
    /// The removal half mirrors the `reorderContainer` closure; only the insertion differs.
    private func insertNewItem(_ section: AppSection, ids: [AppItem.ID]) {
        // Resolved before the loop below shadows `section` with its own binding.
        guard let sectionIndex = sections.firstIndex(where: { $0.id == section.id }) else { return }
        var sourceItems: [AppItem] = []
        for (index, section) in sections.enumerated() {
            if section.apps.contains(ids: ids) {
                sourceItems = section.apps.filtered(by: ids)
                sections[index].apps.remove(ids: ids)
            }
        }
        // The empty-target fallback appends; normal reordering takes over once populated.
        sections[sectionIndex].apps.append(contentsOf: sourceItems)
    }
}

@available(iOS 27.0, *)
private struct AppSectionView: View {
    // This value snapshot is rendered here; the parent performs all section mutations.
    var section: AppSection
    var isMultipleSelectionEnabled: Bool
    @Binding var multipleSelection: Set<AppItem.ID>
    var droppedItemIDs: ([AppItem.ID]) -> Void
    // Drives the dashed highlight while a compatible drop session is active.
    @State private var isDropping: Bool = false
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(section.id)
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundStyle(.gray)

            ScrollView(.vertical) {
                LazyVGrid(columns: Array(repeating: GridItem(), count: 3)) {
                    ForEach(section.apps) { app in
                        Image(app.image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .overlay(alignment: .topLeading) {
                                let isSelected = multipleSelection.contains(app.id)
                                if isMultipleSelectionEnabled {
                                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                        .font(.title3)
                                        .foregroundStyle(.primary, .bar)
                                        .shadow(radius: 5)
                                        .padding(8)
                                }
                            }
                            .clipShape(.rect(cornerRadius: 28))
                            // Match the lifted drag preview to the rounded image card.
                            .contentShape(.dragPreview, .rect(cornerRadius: 28))
                            // A raw `TapGesture` rather than a `Button`: selection must not
                            // compete with the long-press that begins a drag, and the gesture
                            // is disabled outright once editing ends.
                            .gesture(TapGesture().onEnded {
                                if multipleSelection.contains(app.id) {
                                    multipleSelection.remove(app.id)
                                } else {
                                    multipleSelection.insert(app.id)
                                }
                            }, isEnabled: isMultipleSelectionEnabled)
                            .padding(8)
                    }
                    // Connect this ForEach to the matching section in the reorder container.
                    // It modifies `DynamicViewContent`, so it has to sit on the ForEach —
                    // moving it out to the grid would not compile against the same overload.
                    .reorderable(collectionID: section.id)
                }
                .padding(15)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.windowBackground, in: .rect(cornerRadius: 30))
            .overlay {
                if section.apps.isEmpty {
                    // Empty ForEach content has no reorderable cell. This destination
                    // fills that gap and sends its dropped IDs to the parent callback.
                    ContentUnavailableView(
                        "No apps available",
                        systemImage: "app.badge.fill",
                        description: Text("No apps have been added to the section.")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background {
                        RoundedRectangle(cornerRadius: 30)
                            .stroke(.green, style: StrokeStyle(lineWidth: 1, dash: [10, 3]))
                            .opacity(isDropping ? 1 : 0)
                    }
                    // The placeholder is mostly empty space, so give the whole frame a
                    // hit-testable shape or most of the section would not accept a drop.
                    .contentShape(.rect)
                    // Receives `AppItem.ID`, which works because `AppItem` exports its id —
                    // see `transferRepresentation`. The drop location is unused: an empty
                    // section has no geometry to position against.
                    .dropDestination(for: AppItem.ID.self, isEnabled: true) { ids, _ in
                        droppedItemIDs(ids)
                        multipleSelection.removeAll()
                    }
                    // Animate only the visual affordance while the session changes.
                    // Matching `.active` alone means the border appears a beat after
                    // `.entering`, and needs no teardown: `.exiting` and `.ended` both
                    // fail the comparison and clear it.
                    .onDropSessionUpdated { session in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isDropping = session.phase == .active
                        }
                    }
                }
            }
        }
    }
}

@available(iOS 27.0, *)
#Preview {
    ReorderableItemDemo()
}

private struct AppSection: Identifiable {
    // Section identity is also the collection ID used by reorderable.
    var id: String
    var apps: [AppItem]
}

private struct AppItem: Identifiable & Transferable {
    // Reordering and multi-selection use IDs rather than unstable array indices.
    var id: String = UUID().uuidString
    var name: String
    var image: String

    static var transferRepresentation: some TransferRepresentation {
        // Transfer only the ID; the drag container looks up the full model in `sections`.
        // This is also what makes a destination typed on `AppItem.ID` able to receive
        // something dragged as `AppItem`.
        ProxyRepresentation(exporting: \.id)
    }
}

private extension [AppItem] {
    /// Returns matching apps in the collection's current order.
    ///
    /// Order comes from the array, not from `ids`, which is what keeps a multi-item move
    /// from scrambling the selection.
    func filtered(by ids: [String]) -> [AppItem] {
        self.filter { ids.contains($0.id) }
    }

    /// True only when every supplied ID belongs to this section.
    ///
    /// Used to find the one section that owns a payload, so a payload split across two
    /// sections matches neither.
    func contains(ids: [String]) -> Bool {
        ids.allSatisfy { id in
            self.contains { $0.id == id }
        }
    }

    /// Removes all apps represented by a drag or drop payload.
    mutating func remove(ids: [String]) {
        self.removeAll(where: { ids.contains($0.id) })
    }
}
