//
//  AlertApp.swift
//  Alert

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
