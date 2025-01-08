//
//  ContentView.swift
//  Habit

import SwiftUI

struct ContentView: View {
    /// View Properties
    @AppStorage("isIntroCompleted") private var isIntroCompleted: Bool = false

    var body: some View {
        ZStack {
            if isIntroCompleted {
                NavigationStack {
                    HabitHome()
                }
                .transition(.move(edge: .trailing))

            } else {
                IntroPageView()
                    .transition(.move(edge: .leading))
            }
        }
        .animation(.snappy(duration: 0.25, extraBounce: 0), value: isIntroCompleted)
    }
}

#Preview {
    ContentView()
}
