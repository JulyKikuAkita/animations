//
//  Networking.swift
//  PokemonPlay
//
//  Created on 5/25/25.

import Foundation

func fetchPokemonData(name: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
    let urlString = "https://pokeapi.co/api/v2/pokemon/\(name.lowercased())"
    guard let url = URL(string: urlString) else {
        completion(.failure(URLError(.badURL)))
        return
    }

    URLSession.shared.dataTask(with: url) { data, _, error in
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
