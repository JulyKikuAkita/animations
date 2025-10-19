//
//  AppRatingDemoView.swift
//  animation
//
//  Created on 10/11/25.

import StoreKit
import SwiftUI

/// Mock to show prompt when view visited twice, prompt again when visited 4 times
struct AppRatingDemoView: View {
    @State private var updateAppInfo: VersionCheckManager.ReturnResult?
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("Detail View") {
                    Text("hello")
                        .onAppear {
                            let count = UserDefaults.standard.integer(forKey: "ScreenCount")
                            UserDefaults.standard.set(count + 1, forKey: "ScreenCount")
                        }
                }
            }
            .navigationTitle("App Rating")
            .presentAppRating {
                let count = UserDefaults.standard.integer(forKey: "ScreenCount")
                return count >= 2
            } askLaterCondition: {
                let count = UserDefaults.standard.integer(forKey: "ScreenCount")
                return count >= 4
            }
        }
    }
}

extension View {
    @ViewBuilder
    func presentAppRating(
        initialCondition: @escaping () async -> Bool,
        askLaterCondition: @escaping () async -> Bool
    ) -> some View {
        modifier(
            AppRatingModifier(
                initialCondition: initialCondition,
                askLaterCondition: askLaterCondition
            )
        )
    }
}

private struct AppRatingModifier: ViewModifier {
    var initialCondition: () async -> Bool = { false }
    var askLaterCondition: () async -> Bool = { false }
    /// View Properties
    @AppStorage("isRatingInteractionComplete") private var isComplete: Bool = false
    @AppStorage("isInitialPromptComplete") private var isInitialPromptShow: Bool = false
    @State private var showAlert: Bool = false
    @Environment(\.requestReview) private var requestReview
    func body(content: Content) -> some View {
        content
            .task {
                guard !isComplete else { return }
                let condition = await isInitialPromptShow ? askLaterCondition() : initialCondition()
                if condition {
                    showAlert = true
                }
            }
            .alert("Would you like to rate the app?", isPresented: $showAlert) {
                Button(isInitialPromptShow ? "Yes!" : "Yes, Continue!") {
                    requestReview()
                }
                .keyboardShortcut(.defaultAction)

                if isInitialPromptShow {
                    Button("Nope", role: .cancel) {
                        isComplete = true
                    }
                } else {
                    Button("Ask Later", role: .cancel) {
                        isInitialPromptShow = true
                    }

                    Button("Never Ask Me Again", role: .destructive) {
                        isComplete = true
                    }
                }
            }
    }
}
