//
//  Pills.swift
//  PokemonPlay
//
//  Created on 5/25/25.

import SwiftUI

struct PillsListView: View {
    let names: [String]
    let onSelect: (String) -> Void

    private let columns: [GridItem] = [
        GridItem(.adaptive(minimum: 80), spacing: 8),
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(names, id: \.self) { name in
                Button(action: {
                    onSelect(name)
                }) {
                    Text(name.capitalized)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .foregroundColor(.blue)
//                        .background(Color.blue.opacity(0.2))
                        .truncationMode(.tail)
                        .fixedSize(horizontal: true, vertical: false) // prevent text wrapping
                }
                .buttonStyle(.plain) // Prevents default tap animation
                .overlay {
                    Capsule().stroke(.indigo, lineWidth: 1)
                }
                .clipShape(Capsule())
                .contentShape(.capsule) // Ensures tap area matches shape
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    PillsListView(names: ["pikachu", "bulbasaur", "mew", "eevee", "gengar"]) { name in
        print("Selected: \(name)")
    }
}
