//
//  animationApp.swift
//  animation

import SwiftUI
@main
struct AnimationApp: App { // with colorTransformer context
    init() {
        ColorTransformer.register()
    }
    var windowSharedModel = WindowSharedModel()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: ColorModel.self)
                .environment(windowSharedModel)
        }
    }
}
