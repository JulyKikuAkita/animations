//
//  PokemonSpriteData.swift
//  PokemonPlay
//
//  Created on 5/25/25.

import Foundation

struct PokemonSpriteData: Codable {
    struct Sprites: Codable {
        let frontDefault: URL?
    }

    let name: String?
    let sprites: Sprites?
}
