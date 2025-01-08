//
//  HabitApp.swift
//  Habit

import SwiftUI

@main
struct HabitApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: Habit.self)
        }
    }
}
