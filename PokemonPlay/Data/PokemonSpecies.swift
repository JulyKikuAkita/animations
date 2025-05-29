//
//  PokemonSpecies.swift
//  PokemonPlay
//
//  Created on 5/28/25.

import Foundation

struct PokemonSpecies: Codable {
    struct EvolutionChainLink: Codable {
        let url: String
    }

    let evolutionChain: EvolutionChainLink
}
