//
//  ContentView.swift
//  PokemonPlay

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = PokemonViewModel()
    @State private var pokemonName: String = ""
    @State private var isLoading: Bool = false
    @State private var suggestedNames = ["pikachu", "charizard", "bulbasaur", "farfetchd", "snorlax"]

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
                                await viewModel.loadPokemon(name: pokemonName)
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

                if viewModel.isLoading {
                    ProgressView()
                }

                if let error = viewModel.error {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }

                if !viewModel.pokemonNodes.isEmpty {
                    List(viewModel.pokemonNodes) { node in
                        NavigationLink {
                            PokemonDetailsView(node: node)
                                .navigationTitle(node.key.capitalized)
                        } label: {
                            CodedImageView(node: node)
                        }
                        .onTapGesture {
                            // Load evolutions when tapping a Pokémon
                            Task {
                                await viewModel.loadEvolutions(for: node.key)
                            }
                        }
                    }

                    if !viewModel.evolutionNames.isEmpty {
                        EvolutionSectionView(names: viewModel.evolutionNames)
                    }
                } else if viewModel.error != nil {
                    Text("Error: \(viewModel.error!)")
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
            guard viewModel.pokemonNodes.isEmpty else { return }
            await viewModel.loadPokemon(name: "charizard")
        }
        .onChange(of: viewModel.evolutionNames) {
            Task { @MainActor in
                let uniqueNames = Array(Set(suggestedNames + viewModel.evolutionNames))
                suggestedNames = uniqueNames
            }
        }
    }
}

#Preview {
    ContentView()
}
