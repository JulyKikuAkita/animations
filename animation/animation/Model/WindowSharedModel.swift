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
    
    /// Resetting properties
    func reset() {
        sourceRect = .zero
        previousSourceRect = .zero
        hideNativeView = false
        selectedProfile = nil
    }
}
