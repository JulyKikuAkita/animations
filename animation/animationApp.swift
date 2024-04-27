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

//@main
//struct CustomUniversalAlertApp: App {
//    /// Connecting the scene delegate to the swiftUI life-cycle via the delegate adaptor
//    @UIApplicationDelegateAdaptor(AppDelegate.self) private var delegate
//    var body: some Scene {
//        WindowGroup {
//            ContentView()
//        }
//    }
//}
