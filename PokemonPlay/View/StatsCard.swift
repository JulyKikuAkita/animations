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
            VStack {
                HStack {
                    Text("\(stats.primaryType.emoji) \(stats.primaryType.rawValue.capitalized)")
                        .font(.headline)
                    Text(stats.subTypeStrings.joined(separator: ", "))
                        .font(.callout)
                }
                .foregroundStyle(.primary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                HStack {
                    Text("Height:")
                    Text.formatted(stats.height, decimals: 0)
                    Spacer()
                    Text("Weight:")
                    Text.formatted(stats.weight, decimals: 0)
                }
            }

            Divider().padding(.vertical, 4)

            let sortedStats = stats.statValues.sorted { $0.key < $1.key }
            ForEach(Array(sortedStats), id: \.key) { key, val in
                HStack {
                    Text(key.capitalized)
                    Spacer()
                    Text.formatted(val)
                }
            }
        }
        .padding()
        .cornerRadius(12)
        .background(
            LinearGradient(
                colors: stats.typeGradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .edgesIgnoringSafeArea(.top)
    }
}

#Preview {
    let sample = PokemonBasicStats(
        stats: [
            .init(baseStat: 35, stat: .init(name: "hp")),
            .init(baseStat: 55, stat: .init(name: "attack")),
            .init(baseStat: 40, stat: .init(name: "defense")),
            .init(baseStat: 155, stat: .init(name: "special_attack")),
            .init(baseStat: 140, stat: .init(name: "special_defense")),
            .init(baseStat: 90, stat: .init(name: "speed")),
        ],
        height: 10,
        weight: 14,
        types: [
            .init(type: .init(name: .bug)),
            .init(type: .init(name: .ghost)),
            .init(type: .init(name: .fire)),
        ]
    )
    StatsCardView(stats: sample)
}

extension Text {
    static func formatted(_ value: Double, decimals: Int = 2) -> Text {
        Text(String(format: "%.\(decimals)f", value))
    }
}

extension PokemonBasicStats {
    var typeGradientColors: [Color] {
        types.map { $0.type.name.color.opacity(0.5) }
    }

    var subTypeStrings: [String] {
        types
            .map(\.type.name)
            .filter { $0 != primaryType }
            .map(\.rawValue)
    }
}
