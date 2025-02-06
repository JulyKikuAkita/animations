//
//  PanGesture.swift
//  animation
//

import SwiftUI

struct PanGesture: UIGestureRecognizerRepresentable {
    /// ExpandableMusicPlayerView.swift
    var onChange: ((PanGestureValue) -> ())?
    var onEnd: ((PanGestureValue) -> ())?
    
    /// Grid+PanGestureView.swift
    var handle: ((UIPanGestureRecognizer) -> ())?
    
    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        return UIPanGestureRecognizer()
    }
    
    func updateUIGestureRecognizer(_ recognizer: UIPanGestureRecognizer, context: Context) {}
    
    func handleUIGestureRecognizerAction(_ recognizer: UIPanGestureRecognizer, context: Context) {
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
