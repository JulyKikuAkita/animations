//
//  PokemonBasicStats.swift
//  PokemonPlay
//
//  Created on 5/27/25.
import Foundation

struct PokemonBasicStats: Codable {
    let stats: [Stat]

    struct Stat: Codable {
        let baseStat: Double
        let stat: StatName
    }

    struct StatName: Codable {
        let name: String
    }

    var statValues: [String: Double] {
        Dictionary(uniqueKeysWithValues: stats.map { ($0.stat.name, $0.baseStat) })
    }

    var hp: Double? { statValues["hp"] }
    var attack: Double? { statValues["attack"] }
    var defense: Double? { statValues["defense"] }
    var specialAttack: Double? { statValues["special_attack"] }
    var specialDefense: Double? { statValues["special_defense"] }
    var speed: Double? { statValues["speed"] }
}
