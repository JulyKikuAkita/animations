//
//  OnBoardingDM.swift
//  onBoarding
//
//  Created on 8/13/25.

import SwiftUI

private struct OnboardingItem: Identifiable {
    var id: Int
    var view: AnyView
    var maskLocation: CGRect
}

@Observable
private class OnBoardingCoordinator {
    var items: [OnboardingItem] = []
    var overlayWindow: UIWindow?

    var orderedItem: [OnboardingItem] {
        items.sorted { $0.id < $1.id }
    }
}

struct OneTimeOnBoarding<Content: View>: View {
    @AppStorage var isOnBoarded: Bool
    var content: Content
    var beginOnboarding: () async -> Void
    var onBoardingFinished: () -> Void

    init(
        appStorageID: String,
        @ViewBuilder content: @escaping () -> Content,
        beginOnboarding: @escaping () async -> Void,
        onBoardingFinished: @escaping () -> Void
    ) {
        _isOnBoarded = .init(wrappedValue: false, appStorageID)
        self.content = content()
        self.beginOnboarding = beginOnboarding
        self.onBoardingFinished = onBoardingFinished
    }

    fileprivate var coordinator = OnBoardingCoordinator()
    var body: some View {
        content
            .environment(coordinator)
            .task {
                if !isOnBoarded {
                    await beginOnboarding()
                }
            }
    }
}

extension View {
    @ViewBuilder
    func onBoarding(_ position: Int, @ViewBuilder content: @escaping () -> some View) -> some View {
        modifier(
            OnBoardingItemSetter(
                position: position,
                onBoardingContent: content
            )
        )
    }
}

private struct OnBoardingItemSetter<OnboardingContent: View>: ViewModifier {
    var position: Int
    @ViewBuilder var onBoardingContent: OnboardingContent

    @Environment(OnBoardingCoordinator.self) var coordinator
    func body(content: Content) -> some View {
        content
            /// adding/removing item to the coordinator
            .onGeometryChange(for: CGRect.self) {
                $0.frame(in: .global)
            } action: { newValue in
                coordinator.items.removeAll(where: { $0.id == position })
                let newItem = OnboardingItem(
                    id: position,
                    view: .init(onBoardingContent),
                    maskLocation: newValue
                )
                coordinator.items.append(newItem)
            }
            .onDisappear {
                coordinator.items.removeAll(where: { $0.id == position })
            }
    }
}
