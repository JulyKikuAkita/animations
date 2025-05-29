//
//  PokemonDetailsView.swift
//  PokemonPlay
//
//  Created on 5/27/25.

import SwiftUI

struct PokemonDetailsView: View {
    let node: JSONNode
    @State private var isLoading: Bool = false
    @State private var evolutionChain: EvolutionNode? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if let basicStats: PokemonBasicStats = decodePokemon(PokemonBasicStats.self, from: node) {
                    StatsCardView(stats: basicStats)
                } else {
                    Text("Decoding failed")
                        .foregroundColor(.red)
                }

                if let chain = evolutionChain {
                    if isLoading {
                        ProgressView()
                    } else {
                        EvolutionGraphView(node: chain)
                            .padding()
                    }
                }

                JSONTreeView(rootNode: node)
            }
        }
        .task {
            isLoading = true
            guard evolutionChain == nil else { return }
            do {
                evolutionChain = try await fetchEvolutionChain(for: node.key)
            } catch {
                print("Failed to load evolution chain: \(error)")
            }
            isLoading = false
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
