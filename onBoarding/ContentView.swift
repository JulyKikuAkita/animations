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
                .onBoarding(1) {}

                Button("Donwload") {}
                    .padding(15)
                    .onBoarding(2) {}
            }
        } beginOnboarding: {
            <#code#>
        } onBoardingFinished: {
            <#code#>
        }
    }
}

#Preview {
    ContentView()
}
