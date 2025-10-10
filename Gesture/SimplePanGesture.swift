//
//  SimplePanGesture.swift
//  animation
//
//  Created on 10/9/25.
//  Customize to have pan Gesture work on ScrollView
//
// SwiftUI most common Scroll View types:
// 1. scrollView: UIScrollView
// 2. Lust: UICollectionView
//

import SwiftUI

struct SimplePanCustomGesture: UIGestureRecognizerRepresentable {
    var handle: (UIPanGestureRecognizer) -> Void

    func makeCoordinator(converter _: CoordinateSpaceConverter) -> Coordinator {
        Coordinator()
    }

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let gesture = UIPanGestureRecognizer()
        gesture.delegate = context.coordinator
        return gesture
    }

    func updateUIGestureRecognizer(
        _: UIPanGestureRecognizer,
        context _: Context
    ) {}

    func handleUIGestureRecognizerAction(
        _ recognizer: UIPanGestureRecognizer,
        context _: Context
    ) {
        handle(recognizer)
    }

    /// We need to check if the gesture is to for scroll view
    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        func gestureRecognizer(
            _: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            guard let panGesture = gestureRecognizer as? UIPanGestureRecognizer else {
                return false
            }

            /// get direction of drag
            let velocity = panGesture.velocity(in: panGesture.view).y
            var offset: CGFloat = 0

            if let cView = otherGestureRecognizer.view as? UICollectionView {
                offset = cView.contentOffset.y + cView.adjustedContentInset.top
            }

            if let sView = otherGestureRecognizer.view as? UIScrollView {
                offset = sView.contentOffset.y + sView.adjustedContentInset.top
            }

            let isElliglble = Int(offset) <= 1 && velocity > 0
            return isElliglble
        }

        /// check if zoom transition is enabled ? if so use the zoom transition (default) if not use the simple pan gesture
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            let status = (
                gestureRecognizer.view?.gestureRecognizers?.contains(where: {
                    ($0.name ?? "").localizedStandardContains("zoom")
                }) ?? false
            )
            return !status
        }
    }
}
