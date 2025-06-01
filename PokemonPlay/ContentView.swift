//
//  ContentView.swift
//  PokemonPlay

import SwiftUI

struct ContentView: View {
    @State private var pokemonNodes: [JSONNode] = []
    @State private var error: String?
    @State private var pokemonName: String = ""
    @State private var isLoading: Bool = false
    @State private var evolutionChain: EvolutionNode? = nil
    @State private var evolutoinNames: [String] = []
    @State private var suggestedNames = ["pikachu", "charizard", "bulbasaur", "mewtwo", "snorlax"]

    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                VStack(spacing: 6) {
                    HStack {
                        TextField("Enter Pokémon name", text: $pokemonName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)

                        Button("Fetch") {
                            Task {
                                isLoading = true
                                defer { isLoading = false }
                                await loadPokemonAsync(name: pokemonName)
                            }
                        }
                        .disabled(isLoading)
                    }
                    .padding(.horizontal)

                    // Suggested Pills
                    PillsListView(names: suggestedNames) { selectedName in
                        pokemonName = selectedName
                    }
                }

                if let error {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }

                if !pokemonNodes.isEmpty {
                    ImageListView(nodes: pokemonNodes)
                } else if let error {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                        .padding()
                } else {
                    Spacer()
                    Text("Enter a Pokémon name to view its data.")
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            .navigationTitle("Pokémon Statistics")
        }
        .onFirstAppearAsync { /// This task runs every time the view enters the hierarchy.
            guard pokemonNodes.isEmpty else { return }
            await loadPokemonAsync(name: "charizard", isDefault: true)
        }
        .onChange(of: pokemonName) {
            Task {
                let chain = try await fetchEvolutionChain(for: pokemonName)
                evolutoinNames = extractEvolutionNames(from: chain)
                updateSuggestedNames()
            }
        }
    }

    /// Swift Concurrency, support for iOS 15 +
    @MainActor
    private func loadPokemonAsync(name: String, isDefault: Bool = false) async {
        do {
            let wrapped = try await fetchAndWrapPokemonAsync(name: name)
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

        } catch {
            self.error = error.localizedDescription
        }
    }

    private func updateSuggestedNames() {
        guard !evolutoinNames.isEmpty else { return }
        let uniqueNames = Array(Set(suggestedNames + evolutoinNames))
        suggestedNames = uniqueNames
    }
}

#Preview {
    ContentView()
}

extension ContentView {
    /// use Completion Handlers and sync update json, support for iOS 13
    ///  best with
    ///   .onAppear {
    ///     loadPokemon(name: "charizard", isDefault: true)
    /// }
    ///
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
}
