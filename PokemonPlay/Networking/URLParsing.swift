//
//  URLParsing.swift
//  PokemonPlay
//
//  Created on 5/25/25.

import Foundation

/// get Pokemon images
/// sprites.front_default = "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/6.png"
///  for more details at https://github.com/PokeAPI/sprites
///
func extractSpriteURL(from node: JSONNode) -> URL? {
    if case let .object(object) = node.value,
       let sprites = object["sprites"],
       case let .object(spriteDict) = sprites,
       let imageValue = spriteDict["front_default"],
       case let .string(urlString) = imageValue
    {
        return URL(string: urlString)
    }
    return nil
}

// use https://pokeapi.co/api/v2/pokemon-species/pikachu
// to get
// {
//  "evolution_chain": {
//    "url": "https://pokeapi.co/api/v2/evolution-chain/10/"
//  }
// }
func extractEvolutionChainID(from url: String) -> String? {
    URL(string: url)?.lastPathComponent
}

func extractEvolutionNames(from node: EvolutionNode) -> [String] {
    [node.species.name] + node.evolvesTo.flatMap {
        extractEvolutionNames(from: $0)
    }
}
