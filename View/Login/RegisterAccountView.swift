//
//  RegisterAccountView.swift
//  animation
//

import SwiftUI

struct RegisterAccountView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var passwordConfirmation: String = ""
    @State private var isPerforming: Bool = false
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Lets get you started")
                    .font(.title)
                Text("Fill out below form.")
                    .textScale(.secondary)
            }
            .fontWeight(.medium)
            .padding(.top, 5)

            IconTextField(hint: "Email Adress", symbol: "envelop", value: $email)
                .padding(.top, 15)

            IconTextField(hint: "Password", symbol: "lock", isPassword: true, value: $password)

            IconTextField(hint: "Confirm Password", symbol: "lock", isPassword: true, value: $passwordConfirmation)

            TaskButton(title: "Create Account") {} onStatusChange: { isLoading in
                isPerforming = isLoading
            }
            .disabled(!isCreateAccountButtonEnabled)
            .padding(.top, 15)

            Spacer(minLength: 0)

            HStack(spacing: 4) {
                Link("By creating an account, you agree to\nour terms of use and privacy policy.",
                     destination: URL(string: "https://apple.com")!)
                    .font(.caption)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.center)
                    .underline()
            }
            .font(.callout)
            .fontWeight(.medium)
            .foregroundStyle(.primary.secondary)
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding([.horizontal, .top], 20)
        .padding(.bottom, isiOS26OrLater ? 0 : 10)
        .allowsHitTesting(!isPerforming)
        .opacity(isPerforming ? 0.8 : 1)
    }

    var isCreateAccountButtonEnabled: Bool {
        !email.isEmpty && !password.isEmpty && !passwordConfirmation.isEmpty
    }
}
