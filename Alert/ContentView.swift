//
//  ContentView.swift
//  Alert

import SwiftUI

struct ContentView: View {
    var body: some View {
        CustomAlertDemoView()
            .environment(SceneDelegate())
    }
}

#Preview {
    ContentView()
}
