//
//  View+Extension.swift
//  PokemonPlay
//
//  Created on 5/27/25.

import SwiftUI

private struct OnFirstAppearModifier: ViewModifier {
    let action: (() -> Void)?

    @State private var hasAppeared = false

    func body(content: Content) -> some View {
        content.onAppear {
            guard !hasAppeared else { return }
            hasAppeared = true
            action?()
        }
    }
}

private struct OnFirstAppearAsyncModifier: ViewModifier {
    let action: () async -> Void

    @State private var hasAppeared = false

    func body(content: Content) -> some View {
        content.task {
            guard !hasAppeared else { return }
            hasAppeared = true
            await action()
        }
    }
}

public extension View {
    /// Adds an action to perform before this view appears _the first time_ in the view's lifecycle.
    ///
    /// - Parameter action: The action to perform. If `action` is `nil`, the call has no effect.
    /// - Returns: A view that triggers `action` once before it appears.
    func onFirstAppear(_ action: (() -> Void)? = nil) -> some View {
        modifier(OnFirstAppearModifier(action: action))
    }

    /// Adds an async action to perform before this view appears _the first time_ in the view's lifecycle.
    ///
    /// - Parameter action: An async closure to run once on first appearance.
    /// - Returns: A view that triggers the async action once.
    func onFirstAppearAsync(_ action: @escaping () async -> Void) -> some View {
        modifier(OnFirstAppearAsyncModifier(action: action))
    }
}
