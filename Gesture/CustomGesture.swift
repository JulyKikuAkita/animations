//
//  CustomGesture.swift
//  animation

import SwiftUI

struct CustomiOS18Gesture: UIGestureRecognizerRepresentable {
    @Binding var isEnabled: Bool
    /// Only Receives Start and End updates
    var trigger: (Bool) -> Void
    var onChanged: (CGSize, CGPoint) -> Void
    func makeUIGestureRecognizer(context _: Context) -> UIPanGestureRecognizer {
        let gesture = UIPanGestureRecognizer()
        return gesture
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
        let view = recognizer.view
        let location = recognizer.location(in: view)
        let translation = recognizer.translation(in: view)

        let offset = CGSize(width: translation.x, height: translation.y)

        if recognizer.state == .began {
            trigger(true)
        } else if recognizer.state == .ended || recognizer.state == .cancelled {
            trigger(false)
        } else {
            onChanged(offset, location)
        }
    }
}
