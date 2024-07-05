//
//  animationApp.swift
//  animation

import SwiftUI
@main
struct AnimationApp: App { // with colorTransformer context
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    init() {
        ColorTransformer.register()
    }
    var windowSharedModel = WindowSharedModel()
    var body: some Scene {
        WindowGroup {
//            ContentView()
            TabbarOverSheetView()
//                .modelContainer(for: ColorModel.self)
                .environment(windowSharedModel)
        }
    }
}

///  SwiftUI: Placing Tab Bar Over Sheet’s | Apple Map’s Bottom Sheet | iOS 17 | Xcode 15

/// App Delegate
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        
        let config = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        config.delegateClass = SceneDelegate.self /// crash if not set
        return config
    }
}
