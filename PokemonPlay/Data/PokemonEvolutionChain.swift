//
//  PokemonEvolutionChain.swift
//  PokemonPlay
//
//  Created on 5/27/25.

import Foundation

struct PokemonEvolutionChain: Codable {
    struct EvolutionNode: Identifiable, Codable {
        let id: Int // Pokemon ID
        let name: String
        let evolvesTo: [EvolutionNode]
    }

    var root: EvolutionNode
}
