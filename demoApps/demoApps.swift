//
//  demoApps.swift
//  demoApp
//
// App entry point for the `demoApps` target. The actual demo roster lives
// in `ContentView` (see DemoView.swift) — a launcher list that lets you
// pick between demos at runtime instead of swapping `@main` bodies.

import SwiftUI

@main
struct DemoApps: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
