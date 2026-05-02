//
//  AlertApp.swift
//  Alert
//
// Learning points for this demo
// ─────────────────────────────────────────────────────────────────────────
// A SwiftUI `.alert` modifier can't render above a sheet, fullscreen cover,
// or another alert — SwiftUI only has one "top" per window. This demo shows
// how to build a *universal* alert that can appear above anything, by
// hosting it in a separate `UIWindow` at a higher window level.
//
// 1. Bridging SwiftUI ↔ UIKit scene delegate
//    `@UIApplicationDelegateAdaptor(AppDelegate.self)` below wires a UIKit
//    AppDelegate into the SwiftUI App lifecycle. The AppDelegate sets
//    `config.delegateClass = SceneDelegate.self` so UIKit instantiates our
//    custom `SceneDelegate` whenever a scene connects.
//
// 2. The second-window trick (see AppDelegate.swift → setupOverlayWindow)
//    On scene connect, we create a second `UIWindow` tied to the same
//    `UIWindowScene`. It stays hidden until an alert is presented, then we
//    set its rootViewController to a UIHostingController containing the
//    alert view. Because it's a separate window at a higher level, it
//    floats above sheets, tab bars, everything.
//
// 3. The SwiftUI-App lifecycle trap (see ContentView.swift)
//    Under `@main struct: App`, `scene.delegate` is actually a private
//    `SwiftUI.AppSceneDelegate` — *not* our custom `SceneDelegate`. UIKit
//    still instantiates our class and fires `willConnectTo` on it, but we
//    can't reach it via `scene.delegate`. Workaround: stash `self` on
//    `SceneDelegate.current` inside `willConnectTo`, and read from that
//    static when SwiftUI views need it.
//
// 4. Piping state from UIKit back to SwiftUI
//    `SceneDelegate` is `@Observable`, so once it's injected via
//    `.environment(sceneDelegate)`, any view using `@Environment(SceneDelegate.self)`
//    re-renders when its properties change — closing the loop between the
//    UIKit overlay window and SwiftUI state.
// ─────────────────────────────────────────────────────────────────────────

import SwiftUI

@main
struct CustomUniversalAlertApp: App {
    /// Connecting the scene delegate to the swiftUI life-cycle via the delegate adaptor
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
