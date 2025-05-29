//
//  Services.swift
//  PokemonPlay
//
//  Created on 5/25/25.

import Foundation

/// Use Completion Handlers, iOS 13
func fetchPokemonData(
    name: String,
    session: URLSession = .shared, // injecting mock
    completion: @escaping (Result<[String: Any], Error>) -> Void
) {
    let urlString = "https://pokeapi.co/api/v2/pokemon/\(name.lowercased())"
    guard let url = URL(string: urlString) else {
        completion(.failure(URLError(.badURL)))
        return
    }

    session.dataTask(with: url) { data, _, error in
        if let error {
            completion(.failure(error))
            return
        }

        guard let data else {
            completion(.failure(URLError(.badServerResponse)))
            return
        }

        do {
            if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                completion(.success(jsonObject))
            } else {
                completion(.failure(URLError(.cannotParseResponse)))
            }
        } catch {
            completion(.failure(error))
        }
    }.resume()
}

func wrapAsDomainConfig(name: String, original: [String: Any]) -> [String: Any] {
    [
        "domain": [
            "config": [
                name: original,
            ],
        ],
    ]
}

func fetchAndWrapPokemon(name: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
    fetchPokemonData(name: name) { result in
        switch result {
        case let .success(originalJSON):
            let wrapped = wrapAsDomainConfig(name: name, original: originalJSON)
            completion(.success(wrapped))
        case let .failure(error):
            completion(.failure(error))
        }
    }
}

func fetchData(from urlString: String, session: URLSession = .shared) async throws -> Data {
    guard let url = URL(string: urlString) else {
        throw URLError(.badURL)
    }
    let (data, _) = try await session.data(from: url)
    return data
}

/// use swift concurrency, iOS 15+
func fetchPokemonDataAsync(
    name: String,
    session: URLSession = .shared
) async throws -> [String: Any] {
    let urlString = "https://pokeapi.co/api/v2/pokemon/\(name.lowercased())"
    let data = try await fetchData(from: urlString, session: session)

    let jsonObject = try JSONSerialization.jsonObject(with: data)
    guard let json = jsonObject as? [String: Any] else {
        throw URLError(.cannotParseResponse)
    }

    return json
}

func fetchAndWrapPokemonAsync(name: String) async throws -> [String: Any] {
    let rawData = try await fetchPokemonDataAsync(name: name)
    let wrapped = wrapAsDomainConfig(name: name, original: rawData)
    return wrapped
}

func fetchEvolutionChain(
    for pokemon: String,
    session: URLSession = .shared
) async throws -> EvolutionNode {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase

    let speciesURLString = "https://pokeapi.co/api/v2/pokemon-species/\(pokemon)"
    let speciesData = try await fetchData(from: speciesURLString, session: session)
    let species = try decoder.decode(PokemonSpecies.self, from: speciesData)

    guard let id = extractEvolutionChainID(from: species.evolutionChain.url) else {
        throw URLError(.badURL)
    }
    let evolutionURLString = "https://pokeapi.co/api/v2/evolution-chain/\(id)"
    let evolutionData = try await fetchData(from: evolutionURLString, session: session)
    let evolution = try decoder.decode(PokemonEvolutionChain.self, from: evolutionData)
    return evolution.chain
}
