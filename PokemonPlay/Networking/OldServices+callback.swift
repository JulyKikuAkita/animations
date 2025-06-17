//
//  OldServices+callback.swift
//  PokemonPlay
//
//  Created on 5/25/25.

import Foundation

/// use Completion Handlers and sync update json, support for iOS 13
///  best with
///   .onAppear {
///     loadPokemon(name: "charizard", isDefault: true)
/// }
///
var pokemonNodes: [JSONNode] = []
var error: String?
private func loadPokemon(name: String, isDefault: Bool = false) {
    fetchAndWrapPokemon(name: name) { result in
        DispatchQueue.main.async {
            switch result {
            case let .success(wrapped):
                let jsonValue = convertToJSONValue(wrapped)
                if case let .object(dict) = jsonValue,
                   let domain = dict["domain"],
                   let config = domain.children?.first(where: { $0.key == "config" }),
                   let pokemonNode = config.value.children?.first(where: { $0.key == name })
                {
                    if isDefault {
                        pokemonNodes.append(pokemonNode)
                    } else {
                        pokemonNodes.insert(pokemonNode, at: 0)
                    }
                    error = nil
                } else {
                    error = "Invalid structure: missing domain/config/\(name)"
                }
            case let .failure(err):
                error = err.localizedDescription
            }
        }
    }
}
