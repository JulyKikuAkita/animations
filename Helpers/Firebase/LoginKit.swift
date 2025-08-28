//
//  LoginKit.swift
//  animation
//

import FirebaseAuth
import SwiftUI

struct LoginKit<Content: View>: View {
    init(_ appStorageID: String, @ViewBuilder content: @escaping () -> Content) {
        _isLoggedIn = .init(wrappedValue: false, appStorageID)
        /// content after login
        self.content = content()
    }

    private var content: Content
    @AppStorage private var isLoggedIn: Bool
    var body: some View {
        ZStack {
            if !isLoggedIn {
                content
            } else {
                /// Login flow
                LoginView {
                    isLoggedIn = true
                }
            }
        }
        .task {
            if let user = Auth.auth().currentUser, !user.isEmailVerified {
                try? Auth.auth().signOut()
            }
        }
    }
}
