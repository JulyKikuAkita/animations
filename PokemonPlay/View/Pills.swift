//
//  Pills.swift
//  PokemonPlay
//
//  Created on 5/25/25.

import SwiftUI

struct PillsListView: View {
    let names: [String]
    let onSelect: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 8) {
                ForEach(names, id: \.self) { name in
                    Button(action: {
                        onSelect(name)
                    }) {
                        Text(name.capitalized)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal)
        }
        .frame(height: 44)
    }
}

#Preview {
    PillsListView(names: ["pikachu", "bulbasaur", "mew", "eevee", "gengar"]) { name in
        print("Selected: \(name)")
    }
}
