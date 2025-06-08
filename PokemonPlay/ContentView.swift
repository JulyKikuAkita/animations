//
//  ContentView.swift
//  PokemonPlay

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = PokemonViewModel()
    @State private var pokemonName: String = ""
    @State private var isLoading: Bool = false

    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                SearchBarSectionView(
                    pokemonName: $pokemonName,
                    isLoading: $isLoading,
                    suggestions: viewModel.suggestedNames,
                    onSearch: performSearch
                )

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
    }

    func performSearch(_ pokemonName: String) {
        guard !pokemonName.isEmpty else { return }
        Task {
            isLoading = true
            defer { isLoading = false }
            await viewModel.loadPokemon(name: pokemonName)
            await viewModel.loadEvolutions(for: pokemonName)
        }
    }
}

#Preview {
    ContentView()
}

struct SearchBarSectionView: View {
    @Binding var pokemonName: String
    @Binding var isLoading: Bool
    let suggestions: [String]
    let onSearch: (String) -> Void

    @FocusState private var isSearchFocused: Bool

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                TextField("Enter Pokémon name", text: $pokemonName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .submitLabel(.search)
                    .focused($isSearchFocused)
                    .onSubmit { onSearch(pokemonName) }

                Button {
                    isSearchFocused = false
                    onSearch(pokemonName)
                } label: {
                    Image(systemName: "magnifyingglass")
                        .padding(.horizontal, 2)
                }
                .disabled(isLoading)
            }
            .padding(.horizontal)

            // Suggested Pills
            PillsListView(names: suggestions) { selectedName in
                pokemonName = selectedName
                isSearchFocused = false
                onSearch(pokemonName)
            }
            .animation(.easeInOut(duration: 0.25), value: suggestions)
        }
        .onTapGesture {
            isSearchFocused = false
        }
    }
}
