//
//  authOTPApp.swift
//  authOTP
//
//  Created on 8/28/25.

import Firebase
import SwiftUI

@main
struct AuthOTPApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            OTPLoginView {}
        }
    }
}
