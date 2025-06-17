//
//  OrderActionIntent.swift
//  animation
//
//  Created on 6/16/25.

import AppIntents
import SwiftUI

struct OrderActionIntent: AppIntent {
    static var title: LocalizedStringResource = "Order Update"
    // this is a helper to update interactive snippet, no need to be discovered in shortcut, etc
    static var isDiscoverable: Bool = false
    init() {}

    init(isUpdaingPercentage: Bool, isIncremental: Bool) {
        isUpdatingPercentage = isUpdaingPercentage
        self.isIncremental = isIncremental
    }

    @Parameter var isUpdatingPercentage: Bool
    @Parameter var isIncremental: Bool

    @Dependency var manager: IntentOrderManager

    func perform() async throws -> some IntentResult {
        if isUpdatingPercentage {
            if isIncremental {
                manager.count = min(manager.count + 1, 10)
            } else {
                manager.count = max(manager.count - 1, 0)
            }
        } else {
            if isIncremental {
                manager.commision = min(manager.commision + 5, 100)
            } else {
                manager.commision = max(manager.commision - 5, 5)
            }
        }
        return .result()
    }
}
