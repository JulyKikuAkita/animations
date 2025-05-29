//
//  PokemonEvolutionChain.swift
//  PokemonPlay
//
//  Created on 5/27/25.

import Foundation

struct PokemonEvolutionChain: Codable {
    let chain: EvolutionNode
}

struct EvolutionNode: Codable {
    let isBaby: Bool
    let species: NamedAPIResource
    let evolvesTo: [EvolutionNode]
}

struct NamedAPIResource: Codable {
    let name: String
    let url: String
}

extension PokemonEvolutionChain {
    func flatEvolutionNames(from node: EvolutionNode) -> [String] {
        [node.species.name] + node.evolvesTo.flatMap { flatEvolutionNames(from: $0) }
    }
}
