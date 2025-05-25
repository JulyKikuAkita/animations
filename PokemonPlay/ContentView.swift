//
//  ContentView.swift
//  PokemonPlay

import SwiftUI

struct ContentView: View {
    @State private var pokemonNodes: [JSONNode] = []
    @State private var error: String?
    @State private var pokemonName: String = ""

    private let suggestedNames = ["pikachu", "charizard", "bulbasaur", "mewtwo", "snorlax"]

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
                            loadPokemon(name: pokemonName)
                        }
                    }
                    .padding(.horizontal)

                    // Suggested Pills
                    PillsListView(names: suggestedNames) { selectedName in
                        pokemonName = selectedName
                        loadPokemon(name: selectedName)
                    }
                }

                if let error {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }

                if !pokemonNodes.isEmpty {
                    List(pokemonNodes) { node in
                        NavigationLink(destination: JSONTreeView(rootNode: node)
                            .navigationTitle(node.key.capitalized))
                        {
                            Text(node.key.capitalized)
                                .font(.headline)
                        }
                    }
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
        .onAppear {
            loadPokemon(name: "charizard", isDefault: true)
        }
    }

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

#Preview {
    ContentView()
}
