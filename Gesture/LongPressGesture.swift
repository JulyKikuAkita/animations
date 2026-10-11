//
//  LongPressGesture.swift
//  animation
//
//  Created on 10/9/26.
//
// Learning points
// ───────────────────────────────────────────────────────────────────────
// 1. Why UIKit instead of SwiftUI's `LongPressGesture`.
//    SwiftUI's `LongPressGesture` only reports "pressing" and "ended" — it
//    has no finger location and no `.changed` updates after it fires.
//    `UILongPressGestureRecognizer` keeps tracking the finger after the
//    press is recognized (`.began` → `.changed`… → `.ended`), which is what
//    lets the user press, then slide onto a menu item, in one continuous touch.
//
// 2. `UIGestureRecognizerRepresentable` (iOS 18+).
//    Bridges a UIKit recognizer into `.gesture(...)` without a
//    `UIViewRepresentable` overlay. The protocol's associated type is
//    inferred from `makeUIGestureRecognizer`'s return type, so
//    `handleUIGestureRecognizerAction` MUST take the same recognizer type.
//    Gotcha: a mismatched parameter (e.g. `UIPanGestureRecognizer`) still
//    compiles — it's just an unrelated overload, the protocol's default
//    no-op runs instead, and the gesture silently does nothing.
//
// 3. Coordinate spaces.
//    `recognizer.location(in: recognizer.view)` is local to the hosting
//    view. `context.converter.location(in: .global)` converts into SwiftUI
//    coordinate spaces, so the point lines up with `.frame(in: .global)`
//    rects measured elsewhere (source view, menu buttons).
//
// 4. State handling.
//    `.began` fires once after `minimumPressDuration`; `.changed` streams
//    finger moves; every other state (`.ended`, `.cancelled`, `.failed`)
//    is treated as end so the caller always gets a chance to clean up.
// ───────────────────────────────────────────────────────────────────────

import SwiftUI

struct UILongPressGesture: UIGestureRecognizerRepresentable {
    var onBegan: (_ initialLocation: CGPoint) -> Void
    var onChange: (_ location: CGPoint) -> Void
    var onEnd: () -> Void

    func makeUIGestureRecognizer(context _: Context) -> UILongPressGestureRecognizer {
        let gesture = UILongPressGestureRecognizer()
        gesture.minimumPressDuration = 0.3
        gesture.numberOfTouchesRequired = 1
        return gesture
    }

    func handleUIGestureRecognizerAction(_ recognizer: UILongPressGestureRecognizer, context: Context) {
        let state = recognizer.state
        // Global space to match the source viewRect and the full-screen menu overlay
        let location = context.converter.location(in: .global)

        if state == .began {
            onBegan(location)
        } else if state == .changed {
            onChange(location)
        } else {
            onEnd()
        }
    }

    func updateUIGestureRecognizer(_: UILongPressGestureRecognizer, context _: Context) {}
}
