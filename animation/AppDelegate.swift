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

    /// Tab bar demo for SwiftUI: Placing Tab Bar Over Sheet’s | Apple Map’s Bottom Sheet
    var tabWindow: UIWindow?

    func windowScene(_ scene: UIScene, willConnectTo _: UISceneSession, options _: UIScene.ConnectionOptions) {
        windowScene = scene as? UIWindowScene
    }

    /// Adding hero window to the scene
    func addHeroWindow(_ windowSharedModel: WindowSharedModel) {
        guard let scene = windowScene else { return }
        let heroViewController = UIHostingController(rootView:
            CustomHeroAnimationView()
                .environment(windowSharedModel)
                /// Since we don't need any interaction
                .allowsHitTesting(false))

        heroViewController.view.backgroundColor = .clear
        let heroWindow = UIWindow(windowScene: scene)
        heroWindow.rootViewController = heroViewController
        heroWindow.isHidden = false
        heroWindow.isUserInteractionEnabled = false
        /// Storing window reference
        self.heroWindow = heroWindow
    }

    /// SwiftUI: Placing Tab Bar Over Sheet’s | Apple Map’s Bottom Sheet | iOS 17 | Xcode 15
    ///  Adding a new window to display the custom tabbar to control hide/show w/ bottom sheet
    func addTabBar(_ windowSharedModel: WindowSharedModelTabbar) {
        guard let scene = windowScene else { return }
        let tabBarController = UIHostingController(rootView:
            CustomTabBar()
                .environment(windowSharedModel)
                .frame(maxHeight: .infinity, alignment: .bottom)
        )

        tabBarController.view.backgroundColor = .clear
        /// Window
        let tabWindow = UIWindow(windowScene: scene)
        tabWindow.rootViewController = tabBarController
        tabWindow.isHidden = false
        /// Storing tabBar window reference for future use
        self.tabWindow = tabWindow
    }
}

private class PassthroughWindow: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let view = super.hitTest(point, with: event) else { return nil }
        return rootViewController?.view == view ? view : nil
    }
}
