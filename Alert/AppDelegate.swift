//
//  AppDelegate.swift
//  Alert

import SwiftUI

/// App Delegate
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options _: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let config = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        /// Connecting scene delegate
        config.delegateClass = SceneDelegate.self
        return config
    }
}

/// Scene Delegate
///
/// NOTE: under SwiftUI's `App` lifecycle, `scene.delegate` points at
/// `SwiftUI.AppSceneDelegate` — NOT at an instance of this class — even when
/// `config.delegateClass = SceneDelegate.self` is set in the AppDelegate.
/// UIKit still creates our instance and fires `scene(_:willConnectTo:)` on
/// it, so we publish `self` to `SceneDelegate.current` there, and SwiftUI
/// views look it up from that static instead of `scene.delegate`.
@Observable
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    /// The instance UIKit created for the active scene. Set in
    /// `scene(_:willConnectTo:)` — read from SwiftUI views.
    weak static var current: SceneDelegate?

    /// Current scene
    weak var windowScene: UIWindowScene?

    /// overlay window for universal alert
    var overlayWindow: UIWindow?
    var tag = 0 // ID for alert view
    var alerts: [UIView] = []
}

/// Adding scene delegate to the universal alert
extension SceneDelegate {
    func scene(_ scene: UIScene, willConnectTo _: UISceneSession, options _: UIScene.ConnectionOptions) {
        windowScene = scene as? UIWindowScene
        setupOverlayWindow()
        SceneDelegate.current = self
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

    /// viewTag closure returns the tag for the added alert view so we can
    /// remove it later in complex view hierarchies.
    ///
    /// Queueing note: if an alert is already on screen, additional alerts
    /// are appended to `alerts[]` and their `_UIHostingView`s are attached
    /// as subviews of the current rootViewController's view when dismissed
    /// one after another. UIKit logs "Adding ... as a subview of
    /// UIHostingController.view is not supported" for each queued alert;
    /// the warning is expected here and the demo tolerates it in exchange
    /// for showing four alerts from four edges on a single tap.
    func alert(
        config: Binding<AlertConfig>,
        @ViewBuilder content: @escaping () -> some View,
        viewTag: @escaping (
            Int
        ) -> Void
    ) {
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
