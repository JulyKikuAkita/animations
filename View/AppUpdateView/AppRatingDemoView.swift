//
//  AppRatingDemoView.swift
//  animation
//
//  Created on 10/11/25.
//  Standalone demo (not wired into the app's demo browser; preview-only).
//
//  TODO: Cleanup
//        1. The demo persists `ScreenCount` and the two
//           `@AppStorage` flags (`isRatingInteractionComplete`,
//           `isInitialPromptComplete`) in real UserDefaults — once
//           the user picks "Never Ask Me Again" or "Nope", the demo
//           stays silent forever on this install. Add a "Reset"
//           button if you want the demo to be re-runnable, or
//           namespace the keys with a `Demo.` prefix.
//
//  Learning point
//  ──────────────
//  Two-step app-rating prompt that respects user choice. Compares
//  a screen-visit counter to two thresholds:
//    • First threshold (default: 2) → shows the alert with
//      "Yes / Ask Later / Never Ask Me Again."
//    • Second threshold (default: 4, only if user picked "Ask Later"
//      first time) → shows a simpler "Yes / Nope" alert. This
//      respects HIG's "don't keep nagging" rule.
//  When the user picks "Yes," the system rating UI is presented via
//  `@Environment(\.requestReview)` — Apple's preferred rating API
//  (capped at ~3 prompts/year by the OS, so a misconfigured caller
//  can't actually spam users).
//
//  State persistence:
//    • `@AppStorage("isRatingInteractionComplete")` — once true, the
//      whole flow is skipped on every future launch.
//    • `@AppStorage("isInitialPromptComplete")` — true after the
//      user picks "Ask Later"; switches the alert to its
//      second-prompt variant on next eligible launch.
//
//  Key APIs
//  ────────
//  • `@Environment(\.requestReview)` (StoreKit) — preferred over
//    `SKStoreReviewController.requestReview()` since iOS 16. Works
//    in SwiftUI without UIKit reach-through.
//  • `@AppStorage` — UserDefaults binding; declarative and
//    automatically refreshes the view on change.
//  • `View.presentAppRating(initialCondition:askLaterCondition:)`
//    — public API exposed by this file. Both conditions are
//    `() async -> Bool` so callers can run a Core Data / network
//    check before deciding to prompt.
//  • `.alert(...)` with role-based buttons (`.cancel`, `.destructive`)
//    — gets free HIG-compliant button styling on each platform.
//
//  How to apply
//  ────────────
//  Wrap your root navigation view with `.presentAppRating { ... } askLaterCondition: { ... }`.
//  Pass real conditions (e.g., "user completed N onboarding steps,"
//  "user has 3+ saved items"). Don't ask on first launch — too
//  early — and don't tie to launch count alone (low-quality signal).
//
//  See also
//  ────────
//  • AppUpdateDemoView.swift — companion screen that nudges users
//    to update; same folder, different intent (update prompt vs.
//    rating prompt).
//
import StoreKit
import SwiftUI

/// Mock to show prompt when view visited twice, prompt again when visited 4 times
struct AppRatingDemoView: View {
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
