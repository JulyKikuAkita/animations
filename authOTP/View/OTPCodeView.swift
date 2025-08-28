//
//  OTPCodeView.swift
//  authOTP
//
//  Created on 8/28/25.

import SwiftUI

struct OTPView: View {
    var body: some View {
        OTPKit("user_login_status") {
            NavigationStack {
                List {}
                    .navigationTitle("Welcome Back!")
            }
        }
    }
}

#Preview {
    ContentView()
}
