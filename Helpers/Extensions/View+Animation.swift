//
//  View+Animation.swift
//  animation
//
// Purpose: animation-control helpers that wrap SwiftUI's `Transaction` /
// `withAnimation` APIs.
//
// What belongs here:
//   - Global animation toggles (disable animation for a block of work, pin a
//     specific curve, etc.).
//   - Tiny wrappers around `Transaction` that pair a flag with a closure.
//
// What does NOT belong here:
//   - Per-view presentation effects (blur/fade/scale → View+Visibility.swift).
//   - Geometry-driven animations (View+Geometry.swift).
//
// Convention: these are *action* helpers, not view modifiers — they take a
// closure and return Void, and get called imperatively from event handlers
// (`onChange`, button actions, etc.).
//

import SwiftUI

public extension View {
    /// Runs `content` with all SwiftUI animations disabled for that scope.
    ///
    /// Use when a state change inside the closure would otherwise trigger an
    /// unwanted implicit animation (e.g. reassigning a navigation path right
    /// after a transition).
    func withoutAnimation(_ content: @escaping () -> Void) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            content()
        }
    }

    /// Alias for `withoutAnimation`. Kept for call-site compatibility — prefer
    /// `withoutAnimation` in new code so the name matches SwiftUI convention
    /// (`withAnimation` / `withoutAnimation`).
    func noAnimation(_ content: @escaping () -> Void) {
        withoutAnimation(content)
    }
}
