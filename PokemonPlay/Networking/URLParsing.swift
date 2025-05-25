//
//  URLParsing.swift
//  PokemonPlay
//
//  Created on 5/25/25.

import Foundation

/// get Pokemon images
/// sprites.front_default = "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/6.png"
///  for more details at https://github.com/PokeAPI/sprites
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
