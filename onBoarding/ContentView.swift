//
//  ContentView.swift
//  onBoarding
//
//  Created on 8/13/25.

import SwiftUI

struct ContentView: View {
    var body: some View {
        dummyTextView()
    }

    func dummyTextView() -> some View {
        Text("Lorem Ipsum is simply dummy text of the printing and typesetting industry.")
            .font(.caption)
            .multilineTextAlignment(.center)
    }
}

#Preview {
    ContentView()
}
