//
//  StatsCard.swift
//  PokemonPlay
//
//  Created on 5/27/25.

import SwiftUI

struct StatsCardView: View {
    let stats: PokemonBasicStats
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            let sortedStats = stats.statValues.sorted { $0.key < $1.key }
            ForEach(Array(sortedStats), id: \.key) { key, val in
                HStack {
                    Text(key.capitalized)
                    Spacer()
                    Text(String(format: "%.2f", val))
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    let sample = PokemonBasicStats(stats: [
        .init(baseStat: 35, stat: .init(name: "hp")),
        .init(baseStat: 55, stat: .init(name: "attack")),
        .init(baseStat: 40, stat: .init(name: "defense")),
        .init(baseStat: 155, stat: .init(name: "special_attack")),
        .init(baseStat: 140, stat: .init(name: "special_defense")),
        .init(baseStat: 90, stat: .init(name: "speed")),
    ])
    StatsCardView(stats: sample)
}
