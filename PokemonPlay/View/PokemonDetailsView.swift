//
//  PokemonDetailsView.swift
//  PokemonPlay
//
//  Created on 5/27/25.

import SwiftUI

struct PokemonDetailsView: View {
    let node: JSONNode
    @State private var isLoading: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                StatsSectionView(node: node)

                JSONTreeView(rootNode: node)
            }
        }
    }
}

struct StatsSectionView: View {
    let node: JSONNode

    var body: some View {
        if let stats: PokemonBasicStats = decodePokemon(PokemonBasicStats.self, from: node) {
            StatsCardView(stats: stats)
        } else {
            Text("Stats unavailable")
                .foregroundStyle(.red)
        }
    }
}

#Preview("Stats Section with Type") {
    let mockNode = JSONNode(
        key: "pikachu",
        value: .object([
            "weight": .number(6),
            "height": .number(14),
            "types": .array([
                .object([
                    "type": .object([
                        "name": .string("electric"),
                    ]),
                ]),
            ]),
            "sprites": .object([
                "front_default": .string("https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/25.png"),
            ]),
            "stats": .array([
                .object(["base_stat": .number(35), "stat": .object(["name": .string("hp")])]),
                .object(["base_stat": .number(55), "stat": .object(["name": .string("attack")])]),
                .object(["base_stat": .number(40), "stat": .object(["name": .string("defense")])]),
                .object(["base_stat": .number(155), "stat": .object(["name": .string("special_attack")])]),
                .object(["base_stat": .number(140), "stat": .object(["name": .string("special_defense")])]),
                .object(["base_stat": .number(90), "stat": .object(["name": .string("speed")])]),
            ]),
        ])
    )
    StatsSectionView(node: mockNode)
}
