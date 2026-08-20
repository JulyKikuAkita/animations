//
//  Multi-ItemSection+ReorderAPI.swift
//  animation
//
//  Created on 8/19/26.
//  iOS 27 reorderable API + new drag-and-drop API
import SwiftUI

@available(iOS 27.0, *)
struct ReorderableItemDemo: View {
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
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                ForEach(sections) { section in
                    AppSectionView(section: section)
                }
                .reorderContainer(for: AppItem.self, in: AppSection.ID.self) { difference in
                    let sourceIDs = difference.sources
                }
            }
            .padding(15)
            .background(.gray.opacity(0.1))
            .navigationTitle("Reorderable")
            .toolbarTitleDisplayMode(.inlineLarge)
        }
    }
}

@available(iOS 27.0, *)
private struct AppSectionView: View {
    var section: AppSection
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
                            .clipShape(.rect(cornerRadius: 28))
                            /// setting drag preview shap
                            .contentShape(.dragPreview, .rect(cornerRadius: 28))
                            .padding(8)
                    }
                    .reorderable(collectionID: section.id)
                }
                .padding(15)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.windowBackground, in: .rect(cornerRadius: 30))
            .overlay {
                if section.apps.isEmpty {
                    ContentUnavailableView(
                        "No apps available",
                        systemImage: "app.badge.fill",
                        description: Text("No apps have been added to the section.")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .dropDestination(for: AppItem.self, isEnabled: true) { _, _ in
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
    var id: String
    var apps: [AppItem]
}

private struct AppItem: Identifiable & Transferable {
    var id: String = UUID().uuidString
    var name: String
    var image: String

    static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation(exporting: \.id)
    }
}

private extension [AppItem] {
    func filtered(by ids: [String]) -> [AppItem] {
        self.filter { ids.contains($0.id) }
    }

    func contains(ids: [String]) -> Bool {
        ids.allSatisfy { id in
            self.contains { $0.id == id }
        }
    }

    mutating func remove(ids: [String]) {
        self.removeAll(where: { ids.contains($0.id) })
    }
}
