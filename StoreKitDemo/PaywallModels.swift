//
//  PaywallModels.swift
//  animation
//
//  Created on 10/7/25.
import SwiftUI

enum PaywallModels {
    static var productIDs: [String] {
        [
            "paywall_weekly",
            "paywall_monthly",
            "paywall_yearly",
        ]
    }

    static var iapPoints: [PaywallPoints] = [
        .init(symbol: "star", content: "High-quality premium stars"),
        .init(symbol: "arrow.up.circle", content: "Image unlimited arrows"),
        .init(symbol: "paintbrush", content: "Exclusive curtomizable paintbrushes"),
        .init(symbol: "lock.open", content: "Unlock everything with premium access"),
    ]
}

struct PaywallPoints {
    var id: String = UUID().uuidString
    var symbol: String
    var symbolTint: Color = .primary
    var content: String
}
