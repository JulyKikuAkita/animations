//
//  InteractiveOrderIntent.swift
//  animation
//
//  Created on 6/16/25.
//  support iOS 26+

import AppIntents
import SwiftUI

@available(iOS 26.0, *)
struct InteractiveOrderIntent: AppIntent {
    static var title: LocalizedStringResource = "Purchase"
    @Dependency var manager: IntentOrderManager

    func perform() async throws -> some IntentResult & ShowsSnippetView {
        manager.choice = try await requestChoice(
            between: Self.choices,
            dialog: .init("Select Product")
        ).title

        try await requestConfirmation(actionName: .set, snippetIntent: InteractiveOrderConfirmationIntent())
        try await requestConfirmation(actionName: .order, snippetIntent: InteractiveOrderStep2ConfirmationIntent())
        try await manager.mockPlaceOrder()

        return .result(
            view: OrderView(
                choice: manager.choice,
                count: manager.count,
                commision: manager.commision,
                step: .step3
            )
            .padding(.horizontal, 15)
        )
    }

    static var choices: [IntentChoiceOption] {
        [
            .init(title: "Bitcoin"),
            .init(title: "Shiba Inu"),
            .init(title: "Doge"),
        ]
    }
}

/// Setup interactive snippet with SnippetIntent prptocol && request confirmation API
/// to make the view interactiable, similiar to LiveActivities controls
///  the implementation is similar to App Intent
@available(iOS 26.0, *)
struct InteractiveOrderConfirmationIntent: SnippetIntent {
    static var title: LocalizedStringResource = "Step 1"

    @Dependency var manager: IntentOrderManager

    func perform() async throws -> some IntentResult & ShowsSnippetView {
        .result(
            view: OrderView(
                choice: manager.choice,
                count: manager.count,
                commision: manager.commision,
                step: .step1
            )
        )
    }
}

@available(iOS 26.0, *)
struct InteractiveOrderStep2ConfirmationIntent: SnippetIntent {
    static var title: LocalizedStringResource = "Step 2"

    @Dependency var manager: IntentOrderManager

    func perform() async throws -> some IntentResult & ShowsSnippetView {
        .result(
            view: OrderView(
                choice: manager.choice,
                count: manager.count,
                commision: manager.commision,
                step: .step2
            )
        )
    }
}
