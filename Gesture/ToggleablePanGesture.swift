//
//  ToggleablePanGesture.swift
//  animation
//
// A simple pan gesture with an isEnabled toggle.
// Useful when gesture activation depends on external state (e.g. orientation, edit mode).
//

import SwiftUI

@available(iOS 18, *)
struct ToggleablePanGesture: UIGestureRecognizerRepresentable {
    var isEnabled: Bool
    var handle: (UIPanGestureRecognizer) -> Void

    func makeUIGestureRecognizer(context _: Context) -> UIPanGestureRecognizer {
        UIPanGestureRecognizer()
    }

    func updateUIGestureRecognizer(
        _ recognizer: UIPanGestureRecognizer,
        context _: Context
    ) {
        recognizer.isEnabled = isEnabled
    }

    func handleUIGestureRecognizerAction(
        _ recognizer: UIPanGestureRecognizer,
        context _: Context
    ) {
        handle(recognizer)
    }
}
