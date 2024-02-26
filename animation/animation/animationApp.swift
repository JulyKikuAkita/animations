//
//  animationApp.swift
//  animation
//
//  Created by IFang Lee on 2/22/24.
//

import SwiftUI

//@main
//struct animationApp: App {
//    var body: some Scene {
//        WindowGroup {
//            ContentView()
////            HeroWrapper {
////                HeroItemView()
////            }
//        }
//    }
//}

@main
struct SheetHeroAnimationApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    var windowSharedModel = WindowSharedModel()
    var body: some Scene {
        WindowGroup {
            ProfileList_SheetView()
                .environment(windowSharedModel)
        }
    }
}


/// App Delegate
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        
        let config = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        /// Connecting scene delegate
        config.delegateClass = SceneDelegate.self
        return config
    }
}

/// Scene Delegate
@Observable
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    weak var windowScene: UIWindowScene?
    
    /// Hero overlay window
    var heroWindow: UIWindow?
    
    func windowScene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
            windowScene = scene as? UIWindowScene
    }
    
    /// Adding hero window to the scene
    func addHeroWindow(_ windowSharedModel: WindowSharedModel) {
        guard let scene = windowScene else { return }
        let heroViewController = UIHostingController(rootView:
            CustomHeroAnimationView()
            .environment(windowSharedModel)
            /// Since we don't need any interaction
            .allowsHitTesting(false)
        )
        
        heroViewController.view.backgroundColor = .clear
        let heroWindow = UIWindow(windowScene: scene)
        heroWindow.rootViewController = heroViewController
        heroWindow.isHidden = false
        heroWindow.isUserInteractionEnabled = false
        /// Storing window reference
        self.heroWindow = heroWindow
    }
}

struct CustomHeroAnimationView: View {
    @Environment(WindowSharedModel.self) private var windowShareModel
    var body: some View {
        Text("")
    }
}
