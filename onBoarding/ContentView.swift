//
//  ContentView.swift
//  onBoarding
//
//  Created on 8/13/25.

import SwiftUI

struct ContentView: View {
    var body: some View {
        OneTimeOnBoarding(appStorageID: "Home_Turorial") {
            VStack {
                VStack {
                    Image(systemName: "globe")
                        .imageScale(.large)
                        .foregroundStyle(.tint)
                    Text("Hello, world!")
                }
                .padding()
                .onBoarding(1) {
                    dummyTextView()
                }

                Button("Donwload") {}
                    .padding(15)
                    .onBoarding(2) {
                        dummyTextView()
                    }
            }
        } beginOnboarding: {} onBoardingFinished: {}
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
