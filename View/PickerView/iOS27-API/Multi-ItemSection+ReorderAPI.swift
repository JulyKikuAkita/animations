//
//  Multi-ItemSection+ReorderAPI.swift
//  animation
//
//  Created on 8/19/26.
//  Learning notes: iOS 27 reordering combines three responsibilities:
//  1. reorderable(collectionID:) marks each section's ForEach as movable.
//  2. reorderContainer scopes the interaction and applies the resulting move.
//  3. dragContainer supplies transferable values for custom drop destinations.
//
//  The system reorder API needs an existing item to calculate an insertion position.
//  This sample adds a custom drop destination so an empty section can still receive apps.
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
            .dragContainer(for: AppItem.self) { draggedItemIDs in
                var draggedItems: [AppItem] = []
                for section in sections {
                    if section.apps.contains(ids: draggedItemIDs) {
                        draggedItems = section.apps.filtered(by: draggedItemIDs)
                    }
                }
                let selectIDs = Array(multipleSelection)
                // Starting a drag outside the active selection resets that selection.
                if !(isMultipleSelectionEnabled && draggedItems.contains(ids: selectIDs)) {
                    /// cleanup selected IDs
                    multipleSelection.removeAll()
                }
                return draggedItems
            }
            // Passes the current selection to a multi-item drag session.
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
    private func insertNewItem(_ section: AppSection, ids: [AppItem.ID]) {
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
                    .contentShape(.rect)
                    .dropDestination(for: AppItem.ID.self, isEnabled: true) { ids, _ in
                        droppedItemIDs(ids)
                        multipleSelection.removeAll()
                    }
                    // Animate only the visual affordance while the session changes.
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
        ProxyRepresentation(exporting: \.id)
    }
}

private extension [AppItem] {
    /// Returns matching apps in the collection's current order.
    func filtered(by ids: [String]) -> [AppItem] {
        self.filter { ids.contains($0.id) }
    }

    /// True only when every supplied ID belongs to this section.
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
