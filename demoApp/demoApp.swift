//
//  demoApp.swift
//  demoApp

import SwiftUI

/// Switch @main to build the demo app

/// demo apps for
/// AppleMusicHomeView()
/// ApplePhotoHomeView()
/// PinchZoomDemoView()
struct demoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

/// a demo app for Timer: https://pomofocus.io/
@main
struct Pomodoro_TimerApp: App {
    var body: some Scene {
        WindowGroup {
            TimerHomeView()
            /// Injecting  Model
                .modelContainer(for: Recent.self)
        }
    }
}
