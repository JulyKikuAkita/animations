//
//  DynamicTagWidthView.swift
//  animation

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
    "Berserk", "Hunter", "One Piece", "Chainsaw Man", "Tokyo Ghoul", "Solo Leveling", "Naruto", "Monster", "Vagabond", "SpyFamily", "One Punch-Man", "Hero Academia", "Jujutsu Kaisen", "Fullmetal Alchemist", "Pandora Hearts", "Bleach", "Gantz", "Frieren",
]

/// get the size of text view based on the font type
extension String {
    func size(_ font: UIFont) -> CGSize {
        let attributes = [NSAttributedString.Key.font: font]
        return size(withAttributes: attributes)
    }
}

/// new iOS 18 api to create env an container values without boilerplate codes
extension ContainerValues {
    @Entry var viewWidth: CGFloat = 0
}

#Preview {
    DynamicTagWidthDemoView()
}
