//
//  ContentView.swift
//  walletApp

import SwiftUI

struct ContentView: View {
    var body: some View {
        GeometryReader {
            let size = $0.size
            let safeArea = $0.safeAreaInsets
            WalletHomeView(size: size, safeArea: safeArea)
        }
    }
}

#Preview {
    ContentView()
}
