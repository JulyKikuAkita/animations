//
//  AppDelegate.swift
//  Alert

import SwiftUI

/// App Delegate
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options _: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let config = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        /// Connecting scene delegate
        config.delegateClass = SceneDelegate.self
        return config
    }
}

/// Scene Delegate
@Observable
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    /// Current scene
    weak var windowScene: UIWindowScene?

    /// overlay window for universal alert
    var overlayWindow: UIWindow?
    var tag = 0 // ID for alert view
    var alerts: [UIView] = []

//    func windowScene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
//            windowScene = scene as? UIWindowScene
//    }
}

/// Adding scene delegate to the universal alert
extension SceneDelegate {
    func scene(_ scene: UIScene, willConnectTo _: UISceneSession, options _: UIScene.ConnectionOptions) {
        windowScene = scene as? UIWindowScene
        setupOverlayWindow()
    }

    /// Adding hero window to the scene
    func setupOverlayWindow() {
        guard let windowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        window.isHidden = true
        window.isUserInteractionEnabled = false
        overlayWindow = window
        print("window added")
    }

    /// viewTag closure will return the appropriate tag for the added alert view to let us remove the alert in some complex view hierarchy
    func alert(config: Binding<AlertConfig>, @ViewBuilder content: @escaping () -> some View, viewTag: @escaping (Int) -> Void) {
        guard let alertWindow = overlayWindow else { return }

        let viewController = UIHostingController(rootView:
            AlertView(config: config, tag: tag, content: {
                content()
            })
        )

        viewController.view.backgroundColor = .clear
        viewController.view.tag = tag
        viewTag(tag)
        tag += 1 // make sure tag is unique

        if alertWindow.rootViewController == nil {
            print("setup  Alert is Still Present.")
            alertWindow.rootViewController = viewController
            alertWindow.isHidden = false
            alertWindow.isUserInteractionEnabled = true
        } else {
            print("Existing Alert is Still Present.")
            viewController.view.frame = alertWindow.rootViewController?.view.frame ?? .zero
            alerts.append(viewController.view)
        }
    }
}
