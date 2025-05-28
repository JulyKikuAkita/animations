//
//  PokemonDetailsView.swift
//  PokemonPlay
//
//  Created on 5/27/25.

import SwiftUI

struct PokemonDetailsView: View {
    let node: JSONNode
    @State private var showEvolutionChain: Bool = false
    @State private var evolutionNodes: [JSONNode] = []

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if let basicStats: PokemonBasicStats = decodePokemon(PokemonBasicStats.self, from: node) {
                    StatsCardView(stats: basicStats)
                } else {
                    Text("Decoding failed")
                        .foregroundColor(.red)
                }

                JSONTreeView(rootNode: node)
            }
        }
    }
}

#Preview {
    let sample = JSONNode(
        key: "pikachu",
        value: .object([
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
    PokemonDetailsView(node: sample)
}
