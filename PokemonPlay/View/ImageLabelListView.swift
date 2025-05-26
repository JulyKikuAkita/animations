//
//  ImageLabelListView.swift
//  PokemonPlay
//
//  Created on 5/25/25.

import SwiftUI

struct ImageListView: View {
    let nodes: [JSONNode]

    var body: some View {
        List {
            ForEach(nodes) { node in
                NavigationLink(destination: JSONTreeView(rootNode: node)
                    .navigationTitle(node.key.capitalized))
                {
//                    imageView(node)
                    CodedImageView(node: node)
                }
            }
        }
    }

    func imageView(_ node: JSONNode) -> some View {
        HStack(spacing: 12) {
            if let url = extractSpriteURL(from: node) {
                AsyncImage(url: url) { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                } placeholder: {
                    ProgressView()
                        .frame(width: 40, height: 40)
                }
            }
            Text(node.key.capitalized)
                .font(.headline)
        }
        .padding(.vertical, 4)
    }
}

struct CodedImageView: View {
    let node: JSONNode
    var body: some View {
        HStack(spacing: 12) {
            if let data: PokemonSpriteData =
                decodePokemon(PokemonSpriteData.self, from: node),
                let url = data.sprites?.frontDefault
            {
                AsyncImage(url: url) { image in
                    image.resizable().frame(width: 40, height: 40)
                } placeholder: {
                    ProgressView().frame(width: 40, height: 40)
                }
            }
            Text(node.key.capitalized)
        }
    }
}

#Preview {
    let sample = JSONNode(
        key: "pikachu",
        value: .object([
            "sprites": .object([
                "front_default": .string("https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/25.png"),
            ]),
        ])
    )
    return ImageListView(nodes: [sample])
}
