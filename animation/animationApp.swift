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

/// only for  SwiftUI: Placing Tab Bar Over Sheet’s | Apple Map’s Bottom Sheet | iOS 17 | Xcode 15
// @main
struct AnimationTabbar: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var windowSharedModel = WindowSharedModelTabbar()
    var body: some Scene {
        WindowGroup {
            TabbarOverSheetView()
                .environment(windowSharedModel)
        }
    }
}

/// App Delegate
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options _: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let config = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        config.delegateClass = SceneDelegate.self /// crash if not set
        return config
    }
}

/// only for  SwiftUI: Placing Tab Bar Over Sheet’s | Apple Map’s Bottom Sheet | iOS 17 | Xcode 15

// @main
struct SchemeChangeApp: App {
    var body: some Scene {
        WindowGroup {
            SchemeHostView {
                ThemeSwitcherDemoView()
            }
        }
    }
}
