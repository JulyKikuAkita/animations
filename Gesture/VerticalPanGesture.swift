//
//  VerticalPanGesture.swift
//  animation
//
// Vertical-only counterpart to HorizontalPanGesture.
// Activates only when the swipe direction is predominantly vertical.
//

import SwiftUI

@available(iOS 18, *)
struct VerticalPanGesture: UIGestureRecognizerRepresentable {
    var handle: (UIPanGestureRecognizer) -> Void

    func makeCoordinator(converter _: CoordinateSpaceConverter) -> Coordinator {
        Coordinator()
    }

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let gesture = UIPanGestureRecognizer()
        gesture.delegate = context.coordinator
        return gesture
    }

    func updateUIGestureRecognizer(_: UIPanGestureRecognizer, context _: Context) {}

    func handleUIGestureRecognizerAction(_ recognizer: UIPanGestureRecognizer, context _: Context) {
        handle(recognizer)
    }

    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        /// Only activate for vertical swipes (velocity.y > velocity.x)
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let panGesture = gestureRecognizer as? UIPanGestureRecognizer else { return false }
            let velocity = panGesture.velocity(in: panGesture.view)
            return abs(velocity.y) > abs(velocity.x)
        }
    }
}
