//
//  PokemonDetailsView.swift
//  PokemonPlay
//
//  Created on 5/27/25.

import SwiftUI

struct PokemonDetailsView: View {
    let node: JSONNode
    let evolutionChain: EvolutionNode?
    @State private var isLoading: Bool = false
    @State private var evolutoinNames: [String] = []
    var pokemonName: String {
        node.key
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                StatsSectionView(node: node)

                if let chain = evolutionChain {
                    EvolutionSectionView(chain: chain)
                }

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

struct EvolutionSectionView: View {
    let chain: EvolutionNode

    var body: some View {
        Section("Evolution Chain") {
            EvolutionGraphView(node: chain)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
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
    let third = EvolutionNode(
        isBaby: false,
        species: NamedAPIResource(name: "venusaur", url: "https://pokeapi.co/api/v2/pokemon-species/3/"),
        evolvesTo: []
    )
    let evolutionNode = EvolutionNode(
        isBaby: false,
        species: NamedAPIResource(name: "bulbasaur", url: "https://pokeapi.co/api/v2/pokemon-species/1/"),
        evolvesTo: [third]
    )
    PokemonDetailsView(node: sample, evolutionChain: evolutionNode)
}
