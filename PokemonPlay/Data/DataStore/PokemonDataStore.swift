//
//  PokemonDataStore.swift
//  PokemonPlay
//
//  Created on 6/1/25.

import Foundation

// Pure data model (no UI concerns)
class PokemonDataStore {
    private var cachedPokemon: [String: JSONNode] = [:]
    private var cachedEvolutions: [String: [String]] = [:]

    func getPokemon(name: String) async throws -> JSONNode {
        if let cached = cachedPokemon[name.lowercased()] {
            return cached
        }

        let wrapped = try await fetchAndWrapPokemonAsync(name: name)
        let jsonValue = convertToJSONValue(wrapped)

        guard case let .object(dict) = jsonValue,
              let domain = dict["domain"],
              let config = domain.children?.first(where: { $0.key == "config" }),
              let pokemonNode = config.value.children?.first(where: { $0.key.lowercased() == name.lowercased() })
        else {
            throw PokemonError.invalidStructure
        }

        cachedPokemon[name.lowercased()] = pokemonNode
        return pokemonNode
    }

    func getEvolutions(for name: String) async throws -> [String] {
        if let cached = cachedEvolutions[name.lowercased()] {
            return cached
        }

        let chain = try await fetchEvolutionChain(for: name)
        let allNamesInChain = extractEvolutionNames(from: chain)

        // Cache for ALL Pokémon in this chain
        for pokemonName in allNamesInChain {
            cachedEvolutions[pokemonName.lowercased()] = allNamesInChain
        }

        return allNamesInChain
    }
}

// UI State Model (handles presentation logic)
@MainActor
class PokemonViewModel: ObservableObject {
    @Published private(set) var pokemonNodes: [JSONNode] = []
    @Published private(set) var evolutionNames: [String] = []
    @Published private(set) var pinnedNames: [String] = ["pikachu", "charizard", "bulbasaur", "farfetchd", "snorlax"]
    @Published private(set) var error: String?
    @Published private(set) var isLoading = false

    private let dataStore = PokemonDataStore()
    private var searchCounts: [String: Int] = [:]

    var suggestedNames: [String] {
        Array(Set(pinnedNames + evolutionNames)).sorted { lh, rh in
            // most searched first
            searchCounts[lh, default: 0] > searchCounts[rh, default: 0]
        }
    }

    func loadPokemon(name: String) async {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        do {
            let node = try await dataStore.getPokemon(name: name)
            pokemonNodes.insert(node, at: 0)
            searchCounts[name, default: 0] += 1
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func loadEvolutions(for name: String) async {
        do {
            let evolutions = try await dataStore.getEvolutions(for: name)
            evolutionNames = evolutions
        } catch {
            self.error = error.localizedDescription
        }
    }
}
