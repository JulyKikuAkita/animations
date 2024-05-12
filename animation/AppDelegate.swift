//
//  AppDelegate.swift
//  animation
//

import SwiftUI

/// Scene Delegate
@Observable
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    /// Current scene
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
