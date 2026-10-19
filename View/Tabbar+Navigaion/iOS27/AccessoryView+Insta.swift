//
//  InstaSwipeToCameraView.swift
//  animation
//
//  Created on 10/18/26.
//  Instagram's Swipeable Feed-to-Camera Interaction
import SwiftUI

@available(iOS 26.0, *)
struct InstaSwipeToCameraView<Accessory: View, Content: View>: View {
    var isEnabled: Bool
    @Binding var isVisible: Bool
    @ContentBuilder var accessory: (_ visibilityProgress: CGFloat) -> Accessory
    @ContentBuilder var content: (_ visibilityProgress: CGFloat) -> Content
    /// View Properties
    @State private var progress: CGFloat = 0
    @State private var containerSize: CGSize = .zero
    var body: some View {
        content(progress)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                ConcentricRectangle(corners: .concentric, isUniform: true)
                    .fill(.windowBackground)
                    .ignoresSafeArea()
            }
            .mask {
                ConcentricRectangle(corners: .concentric, isUniform: true)
                    .ignoresSafeArea()
            }
            .compositingGroup()
            .offset(x: progress * containerSize.width)
            .background {
                accessory(progress)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .compositingGroup()
                    .offset(x: (1 - progress) * (-containerSize.width / 6))
            }
            .contentShape(.rect)
            .gesture(
                VisPanGesture(isEnabled: isEnabled, isVisible: $isVisible) { gesture in
                    let state = gesture.state
                    let translation = gesture.translation(in: gesture.view).x + (isVisible ? containerSize.width : 0)
                    let velocity = gesture.velocity(in: gesture.view).x / 5

                    if state == .began || state == .changed {
                        let progress = translation / containerSize.width
                        self.progress = progress.clamped(to: 0 ... 1)
                    } else {
                        withAnimation(.iSpring()) {
                            let endResult = translation + velocity
                            if endResult > (containerSize.width / 2) {
                                isVisible = true
                                progress = 1
                            } else {
                                isVisible = false
                                progress = 0
                            }
                        }
                    }
                }
            )
            .onGeometryChange(for: CGSize.self) {
                $0.size
            } action: { newValue in
                containerSize = newValue
            }
            .onChange(of: isVisible) { _, newValue in
                withAnimation(.iSpring()) {
                    if newValue, progress != 1 {
                        progress = 1
                    }

                    if !newValue, progress != 0 {
                        progress = 0
                    }
                }
            }
    }
}

private struct VisPanGesture: UIGestureRecognizerRepresentable {
    var isEnabled: Bool
    @Binding var isVisible: Bool
    var handle: (UIPanGestureRecognizer) -> Void

    func makeCoordinator(converter _: CoordinateSpaceConverter) -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let gesture = UIPanGestureRecognizer()
        gesture.maximumNumberOfTouches = 1
        gesture.delegate = context.coordinator
        return gesture
    }

    func updateUIGestureRecognizer(_ recognizer: UIPanGestureRecognizer, context _: Context) {
        recognizer.isEnabled = isEnabled
    }

    func handleUIGestureRecognizerAction(_ recognizer: UIPanGestureRecognizer, context _: Context) {
        handle(recognizer)
    }

    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var parent: VisPanGesture
        init(parent: VisPanGesture) {
            self.parent = parent
        }

        /// custom behavior to ignore other simultaneous gestures
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            if let panGesture = gestureRecognizer as? UIPanGestureRecognizer {
                let velocity = panGesture.velocity(in: panGesture.view)
                let isHorizontalSwipe = abs(velocity.x) > abs(velocity.y)

                return (isHorizontalSwipe && velocity.x > 0) || (
                    isHorizontalSwipe && velocity.x < 0 && parent.isVisible
                )
            }
            return false
        }

        /// Coexistence with horizontal scroll views: wait for a scroll view's pan to fail only when it is
        /// at its leading edge. Any other recognizer (e.g. SwiftUI Buttons in the feed header) must not
        /// block this pan, otherwise the swipe never begins on screens that contain them.
        func gestureRecognizer(
            _: UIGestureRecognizer,
            shouldBeRequiredToFailByOtherGestureRecognizer otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            if let scrollView = otherGestureRecognizer.view as? UIScrollView {
                let offset = scrollView.contentOffset.x
                return offset <= 0
            }
            return false
        }
    }
}
