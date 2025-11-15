//
//  OneTimeOnBoardingDemoView.swift
//  onBoarding
//
//  Created on 11/15/25.

import SwiftUI

struct OneTimeOnBoardingDemoView: View {
    var body: some View {
        OneTimeOnBoarding(appStorageID: "Home_Tutorial") {
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

                Button("Download") {}
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
    OneTimeOnBoardingDemoView()
}
