//
//  RegisterAccountView.swift
//  animation
//

import FirebaseAuth
import SwiftUI

struct RegisterAccountView: View {
    var onSuccessLogin: () -> Void = {}

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var passwordConfirmation: String = ""
    @State private var isPerforming: Bool = false
    @State private var alert: AlertModal = .init(message: "")
    @State private var userVerificationModal: Bool = false
    @Environment(\.dismiss) var dismiss
    @FocusState private var isFocused: Bool

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
        .focused($isFocused)
        .customAlert($alert)
        .sheetAlert(
            isPresented: $userVerificationModal,
            prominentSymbol: "envelop.badge",
            title: "Email Verification",
            message: "We have sent a verification email to\nyour address. Please check your inbox.",
            primaryButtonTitle: "Verified",
            primaryButtonAction: {
                if let user = Auth.auth().currentUser {
                    try? await user.reload()
                    if user.isEmailVerified {
                        debugPrint("User email verified")
                        dismiss()
                        onSuccessLogin()
                    }
                }
            }
        )
        /// Disabling interactive dismiss when keybaord is active/ isPerforming action
        .interactiveDismissDisabled(isFocused || isPerforming)
    }

    var isCreateAccountButtonEnabled: Bool {
        !email.isEmpty && !password.isEmpty && !passwordConfirmation.isEmpty
    }

    private func createNewAccount() async {
        do {
            let auth = Auth.auth()
            let result = try await auth.createUser(
                withEmail: email,
                password: password
            )
            try await result.user.sendEmailVerification()
            userVerificationModal = true
        } catch {
            // TBD: double check if user is created but email failed to send, need to clean up user
            alert.message = error.localizedDescription
            alert.show = true
        }
    }
}
