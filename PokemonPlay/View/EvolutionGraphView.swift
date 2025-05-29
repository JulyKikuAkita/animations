//
//  EvolutionGraphView.swift
//  PokemonPlay
//
//  Created on 5/28/25.

import SwiftUI

struct EvolutionGraphView: View {
    let node: EvolutionNode

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack {
                Text(node.species.name.capitalized)
                    .font(.headline)
            }

            if let next = node.evolvesTo.first {
                Image(systemName: "arrow.right")
                EvolutionGraphView(node: next)
            }
        }
    }
}

#Preview {
    let third = EvolutionNode(
        isBaby: false,
        species: NamedAPIResource(name: "venusaur", url: "https://pokeapi.co/api/v2/pokemon-species/3/"),
        evolvesTo: []
    )
    let second = EvolutionNode(
        isBaby: false,
        species: NamedAPIResource(name: "ivysaur", url: "https://pokeapi.co/api/v2/pokemon-species/2/"),
        evolvesTo: [third]
    )
    let first = EvolutionNode(
        isBaby: false,
        species: NamedAPIResource(name: "bulbasaur", url: "https://pokeapi.co/api/v2/pokemon-species/1/"),
        evolvesTo: [second]
    )
    return EvolutionGraphView(node: first)
}
