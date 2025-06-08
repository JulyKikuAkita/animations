//
//  ImageLabelListView.swift
//  PokemonPlay
//
//  Created on 5/25/25.

import SDWebImage
import SDWebImageSwiftUI
import SwiftUI

/// Use web image
///  https://github.com/SDWebImage/SDWebImageSwiftUI
struct CodedImageView: View {
    let node: JSONNode
    @State private var loaded = false
    var body: some View {
        HStack(spacing: 12) {
            if let url = extractSpriteURL(from: node) {
                WebImage(url: url) { image in
                    image.resizable().scaledToFit()
                        .aspectRatio(contentMode: .fill)
                        .clipShape(.circle)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: loaded)
                        .frame(width: 40, height: 40)

                } placeholder: {
                    ProgressView()
                }
                .onSuccess { _, _, _ in
                    loaded = true
                }
                .indicator(.activity)
                .transition(.fade(duration: 0.5))
            }
            Text(node.key.capitalized)
                .font(.headline)
        }
        .frame(height: 60, alignment: .center) // fix row height for predictable layout size
    }
}

struct AsyncImageView: View {
    let node: JSONNode
    var body: some View {
        HStack(spacing: 12) {
            if let url = extractSpriteURL(from: node) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFit()
                        .aspectRatio(contentMode: .fill)
                        .clipShape(.circle)
                        .frame(width: 40, height: 40)
                } placeholder: {
                    ProgressView()
                }
            }
            Text(node.key.capitalized)
                .font(.headline)
        }
        .frame(height: 60, alignment: .center)
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
    Section("WebImage") {
        CodedImageView(node: sample)
    }
    Section("AsyncImage") {
        AsyncImageView(node: sample)
    }
}
