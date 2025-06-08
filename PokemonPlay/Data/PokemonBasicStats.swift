//
//  PokemonBasicStats.swift
//  PokemonPlay
//
//  Created on 5/27/25.
import SwiftUI

struct PokemonBasicStats: Codable {
    let stats: [Stat]
    let height: Double
    let weight: Double
    let types: [TypeEntry]

    struct Stat: Codable {
        let baseStat: Double
        let stat: StatName
    }

    struct StatName: Codable {
        let name: String
    }

    struct TypeEntry: Codable {
        let type: NamedType

        struct NamedType: Codable {
            let name: PokemonType
        }
    }

    var primaryType: PokemonType {
        types.first?.type.name ?? .unknownType
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

enum PokemonType: String, Codable, CaseIterable {
    case normal, fighting, flying, poison, ground
    case rock, bug, ghost, steel
    case fire, water, grass, electric, psychic
    case ice, dragon, dark, fairy
    case unknown, shadow
    case unknownType

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        self = PokemonType(rawValue: raw) ?? .unknownType
    }

    var color: Color {
        switch self {
        case .fire: .red
        case .water: .blue
        case .electric: .yellow
        case .grass: .green
        case .psychic: .indigo
        case .fighting: .orange
        default: Color(.systemGray6)
        }
    }

    var emoji: String {
        switch self {
        case .fire: "🔥"
        case .water: "💧"
        case .electric: "⚡️"
        case .grass: "🌿"
        case .ice: "❄️"
        case .ghost: "👻"
        default: "🔹"
        }
    }
}
