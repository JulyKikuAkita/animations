//
//  PanGesture.swift
//  animation
//

import SwiftUI

struct PanGesture: UIGestureRecognizerRepresentable {
    /// ExpandableMusicPlayerView.swift
    var onChange: ((PanGestureValue) -> Void)?
    var onEnd: ((PanGestureValue) -> Void)?

    /// Grid+PanGestureView.swift
    var handle: ((UIPanGestureRecognizer) -> Void)?

    func makeUIGestureRecognizer(context _: Context) -> UIPanGestureRecognizer {
        UIPanGestureRecognizer()
    }

    func updateUIGestureRecognizer(_: UIPanGestureRecognizer, context _: Context) {}

    func handleUIGestureRecognizerAction(_ recognizer: UIPanGestureRecognizer, context _: Context) {
        if #available(iOS 18.0, *) {
            let state = recognizer.state
            let translation = recognizer.translation(in: recognizer.view).toSize()
            let velocity = recognizer.velocity(in: recognizer.view).toSize()
            let value = PanGestureValue(translation: translation, velocity: velocity)

            if state == .began || state == .changed {
                onChange?(value)
            } else {
                onEnd?(value)
            }
        } else {
            handle?(recognizer)
        }
    }
}

extension CGPoint {
    func toSize() -> CGSize {
        .init(width: x, height: y)
    }
}
