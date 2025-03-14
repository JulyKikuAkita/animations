//
//  ContentView.swift
//  DocumentScannerApp

import SwiftData
import SwiftUI

struct ContentView: View {
    @AppStorage("showIntroView") var showIntroView: Bool = true
    var body: some View {
        HomeView()
            .sheet(isPresented: $showIntroView) {
                AppleDocIntroScreen()
                    .interactiveDismissDisabled()
            }
    }
}

#Preview {
    ContentView()
}
