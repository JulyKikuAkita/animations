//
//  JSONTreeView.swift
//  PokemonPlay
//
//  Created on 5/25/25.

import SwiftUI

struct JSONTreeView: View {
    let rootNode: JSONNode

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 4) {
                OutlineGroup([rootNode], children: \.value.children) { node in
                    HStack(alignment: .top) {
                        Text(node.key)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.blue)
                        Spacer()
                        Text(node.value.display)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.trailing)
                    }
                    .padding(.vertical, 2)
                }
            }
            .padding()
        }
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    let sample = JSONNode(key: "sample", value: .object([
        "name": .string("pikachu"),
        "hp": .number(35),
        "type": .array([.string("electric")]),
    ]))
    return JSONTreeView(rootNode: sample)
}
