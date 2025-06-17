//
//  OrderManager.swift
//  animation
//
//  Created on 6/16/25.

import AppIntents
import SwiftUI

// @main
struct IntenrOrderApp: App {
    init() {
        AppDependencyManager.shared.add { IntentOrderManager() }
    }

    var body: some Scene {
        WindowGroup {
            OrderView(choice: "Bitcoin", count: 1, commision: 10)
        }
    }
}

class IntentOrderManager {
    var choice: LocalizedStringResource = ""
    var count: Int
    var commision: Int

    init(choice: LocalizedStringResource = "Doge", count: Int = 1, commision: Int = 10) {
        self.choice = choice
        self.count = count
        self.commision = commision
    }

    func mockPlaceOrder() async throws {
        try await Task.sleep(for: .seconds(1))
        print(
            "send order request \(choice) x \(count) with comisión \(commision)"
        )
    }
}
