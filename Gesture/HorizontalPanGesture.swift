//
//  HorizontalPanGesture.swift
//  animation
//
// CustomSwipeActionScrollViewiOS18DemoView

import SwiftUI

struct PanGestureValue {
    var translation: CGSize = .zero
    var velocity: CGSize = .zero
}

@available(iOS 18, *)
struct HorizontalPanGesture: UIGestureRecognizerRepresentable {
    var onBegan: () -> Void
    var onChange: (PanGestureValue) -> Void
    var onEnd: (PanGestureValue) -> Void

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let gesture = UIPanGestureRecognizer()
        gesture.delegate = context.coordinator
        return gesture
    }

    func updateUIGestureRecognizer(_: UIPanGestureRecognizer, context _: Context) {}

    func handleUIGestureRecognizerAction(_ recognizer: UIPanGestureRecognizer, context _: Context) {
        let state = recognizer.state
        let translation = recognizer.translation(in: recognizer.view).toSize()
        let velocity = recognizer.velocity(in: recognizer.view).toSize()
        let gestureValue = PanGestureValue(translation: translation, velocity: velocity)

        switch state {
        case .began:
            onBegan()
        case .changed:
            onChange(gestureValue)
        case .ended:
            onEnd(gestureValue)
        default:
            break
        }
    }

    func makeCoordinator(converter _: CoordinateSpaceConverter) -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        /// Limiting gesture activation for only horizontal swipe (no vertical swipe) to satisfy swipe action in scroll view
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            if let panGesture = gestureRecognizer as? UIPanGestureRecognizer {
                let velocity = panGesture.velocity(in: panGesture.view)

                /// Horizontal swipe
                if abs(velocity.x) > abs(velocity.y) {
                    return true
                } else {
                    return false
                }
            }
            return false
        }
    }
}
