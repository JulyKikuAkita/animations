//
//  InstaSwipeToCameraView.swift
//  animation
//
//  Created on 10/18/26.
//  Instagram's Swipeable Feed-to-Camera Interaction
//
//  Learning point
//  ──────────────
//  The swipe is a UIKit `UIPanGestureRecognizer` bridged with
//  `UIGestureRecognizerRepresentable`, not a SwiftUI `DragGesture`,
//  because it needs delegate control over how it competes with the
//  scroll views and SwiftUI gestures inside `content`.
//
//  Once bridged, SwiftUI's own gestures (DragGesture, Button, …) are
//  just more UIKit recognizers to it, of the private type
//  `UIKitResponderGestureRecognizer`. They take part in UIKit's normal
//  arbitration, whose delegate calls arrived in this order in the
//  debug logs for this bug (UIKit doesn't document a strict order):
//
//    1. `shouldReceive touch`        – does it see the touch at all?
//    2. `shouldRecognizeSimultaneouslyWith` – asked against every
//       recognizer that has already begun. If both sides say `false`,
//       the one that began first wins and the newcomer FAILS here.
//    3. `gestureRecognizerShouldBegin` – only reached if step 2 passed.
//    4. `shouldBeRequiredToFailBy`   – "wait for that one to fail first".
//
//  Bug: on the Feed tab the swipe never opened the camera, though it
//  worked on every other tab and the `+` button / swipe back worked.
//  Debug prints showed step 1 and step 2 firing on Feed, with
//  `other=UIKitResponderGestureRecognizer state=1` (`.began`), but step
//  3 never ran. Something in `FeedView` begins a SwiftUI gesture on
//  touch-down (a likely candidate is a zero-distance `DragGesture`),
//  and the delegate's default `false` from step 2 made our pan lose
//  before it could even check the swipe direction. The exact culprit
//  wasn't isolated; the fix doesn't depend on it.
//
//  Fix: allow simultaneous recognition with everything except scroll
//  views. Scroll views stay exclusive so the feed doesn't scroll while
//  the camera slides in, and the horizontal stories row is handled by
//  step 4 instead.
//
//  Debugging tip: when a bridged recognizer "does nothing", print in
//  each delegate method. The last one that prints tells you which
//  step rejected it, and logging `type(of: other)` / `other.state` in
//  step 2 names the recognizer you're losing to.
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
                    // Parallax: the camera starts 1/6 width off to the left and moves slower than the feed.
                    .offset(x: (1 - progress) * (-containerSize.width / 6))
            }
            .contentShape(.rect)
            .gesture(
                VisPanGesture(isEnabled: isEnabled, isVisible: $isVisible) { gesture in
                    let state = gesture.state
                    // Translation is relative to where the drag started; when closing, the feed starts a full
                    // width to the right, so shift it to get the feed's absolute position.
                    let translation = gesture.translation(in: gesture.view).x + (isVisible ? containerSize.width : 0)
                    // Damped velocity projects where a flick would land, so a quick short swipe still commits.
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
            // Keeps `progress` in sync when `isVisible` is set outside the gesture (the `+` button, the
            // camera's close button). The guards skip the gesture's own end, which already set `progress`.
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

        /// Starts only for a mostly-horizontal swipe: rightward opens the camera, leftward only when it is
        /// already open (to close it). Vertical drags fail here, leaving them to the feed's scroll view.
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

        /// SwiftUI gestures in `content` can already be `.began` on touch-down; returning `false` against them
        /// makes this pan fail before `gestureRecognizerShouldBegin` runs (the Feed-tab bug, see file header).
        /// Scroll views stay exclusive so the feed never scrolls while the camera slides in; horizontal ones
        /// are arbitrated by `shouldBeRequiredToFailBy` below.
        func gestureRecognizer(
            _: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer
        ) -> Bool {
            !(other.view is UIScrollView)
        }

        /// Wait for a scroll view's pan to fail only when it is at its leading edge (e.g. the stories row
        /// scrolled to the start), so an inner horizontal scroller scrolls first and the camera opens once it
        /// can't scroll further left. Returning `true` for other recognizers would make this pan wait on every
        /// Button / SwiftUI gesture and never begin.
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
