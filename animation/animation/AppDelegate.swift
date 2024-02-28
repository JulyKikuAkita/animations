//
//  AppDelegate.swift
//  animation
//

import SwiftUI

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
