//
//  animationApp.swift
//  animation

import SwiftUI
@main
struct AnimationApp: App { // with colorTransformer context
    init() {
        ColorTransformer.register()
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: ColorModel.self)
        }
    }
}
