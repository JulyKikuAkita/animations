//
//  OnBoardingApp.swift
//  onBoarding
//
//  Created on 8/13/25.

import SwiftUI

// @main
struct OnBoardingApp: App {
    var body: some Scene {
        /// since each logo is different, play around to get the best scaling config to achieve smooth scaling animation
        LaunchScreen(config: .init(scaling: 9)) {
            // Image(.redIcon) /// matches the launch screen logo name in the info.plist
            Image(systemName: "playstation.logo")
                .font(.system(size: 100))
        } rootContent: {
            ContentView()
        }
    }
}
