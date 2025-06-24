//
//  WindowSharedModel.swift
//  animation
//
//  Use multiple windows to achieve hero animation effect
//

import SwiftUI

@Observable
class WindowSharedModel {
    var sourceRect: CGRect = .zero
    var previousSourceRect: CGRect = .zero
    var hideNativeView: Bool = false
    var selectedProfile: Profile?
    var cornerRadius: CGFloat = 0
    var showGradient: Bool = false

    /// Resetting properties
    func reset() {
        sourceRect = .zero
        previousSourceRect = .zero
        hideNativeView = false
        selectedProfile = nil
        cornerRadius = 0
        showGradient = false
    }
}

/// SwiftUI: Placing Tab Bar Over Sheet’s | Apple Map’s Bottom Sheet | iOS 17 | Xcode 15
@Observable
class WindowSharedModelTabbar {
    var activeTab: TabiOS17 = .apps
}
