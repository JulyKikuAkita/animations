//
//  authOTPApp.swift
//  authOTP
//
//  Created on 8/28/25.

import Firebase
import FirebaseAuth
import SwiftUI

@main
struct AuthOTPApp: App {
    // Fireabse configure can only be called once // this is for email/password demo
//    init() {
//        if FirebaseApp.app() == nil {
//            FirebaseApp.configure()
//        }
//    }

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup {
            OTPView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    // Fireabse configure can only be called once // this is for mobile sms otp
    func application(
        _: UIApplication,
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        return true
    }

    /// Phone Auth requires did didReceiveRemoteNotification delegate method!
    func application(_: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void)
    {
        /// Handling silent Firebase Notification
        if Auth.auth().canHandleNotification(userInfo) {
            completionHandler(.noData)
        }
    }

    func application(_: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data)
    {
        #if DEBUG
            Auth.auth().setAPNSToken(deviceToken, type: .sandbox)
        #else
            Auth.auth().setAPNSToken(deviceToken, type: .prod)
        #endif
    }
}
