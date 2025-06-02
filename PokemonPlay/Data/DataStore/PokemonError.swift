//
//  PokemonError.swift
//  PokemonPlay
//
//  Created on 6/1/25.

import Foundation

enum PokemonError: Error, LocalizedError {
    case invalidStructure
    case notFound
    case evolutionChainUnavailable
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidStructure:
            "Invalid Pokémon data structure"
        case .notFound:
            "Pokémon not found"
        case .evolutionChainUnavailable:
            "Evolution data unavailable"
        case let .networkError(error):
            "Network error: \(error.localizedDescription)"
        }
    }
}
