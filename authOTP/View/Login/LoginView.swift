//
import FirebaseAuth

//  LoginKit.swift
//  animation
//
// allow Hit testing removes keyboard when task is loading but once it's finished keyboard becomes active
// use focusState to hide keyboard before task finish
import SwiftUI

struct LoginView: View {
    var onSuccessLogin: () -> Void = {}
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var createAccount: Bool = false
    @State private var forgotPassword: Bool = false
    @State private var userNotVerified: Bool = false
    @State private var isPerforming: Bool = false
    @State private var alert: AlertModal = .init(message: "")
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Welcome Back")
                    .font(.largeTitle)
                Text("Please Sign in to continue.")
                    .font(.callout)
            }
            .fontWeight(.medium)
            .padding(.top, 5)

            IconTextField(hint: "Email Adress", symbol: "envelop", value: $email)
                .padding(.top, 15)

            IconTextField(hint: "Password", symbol: "lock", isPassword: true, value: $password)

            Button("Forgot Password?") {
                forgotPassword.toggle()
            }
            .padding(.top, 4)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .tint(.primary)

            TaskButton(title: "Sign in") {
                isFocused = false
                await login()
            } onStatusChange: { isLoading in
                isPerforming = isLoading
            }
            .disabled(!isSignInButtonEnabled)
            .padding(.top, 15)

            HStack(spacing: 4) {
                Text("Don't have an account?")
                Button("Sign up Here") {
                    createAccount.toggle()
                }
                .underline()
            }
            .font(.callout)
            .fontWeight(.medium)
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity)

            Spacer(minLength: 0)

            HStack(spacing: 4) {
                Link("Terms of Service", destination: URL(string: "https://apple.com")!)
                    .underline()
                Text("&")
                Link("Privacy Polict", destination: URL(string: "https://apple.com")!)
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
        .sheet(isPresented: $createAccount) {
            RegisterAccountView(onSuccessLogin: onSuccessLogin)
                .presentationDetents([.height(400)])
                .presentationBackground(.background)
                /// iOS 26 auto-adopt cornerRadius as devices
                .presentationCornerRadius(isiOS26OrLater ? nil : 30)
        }
        .sheet(isPresented: $forgotPassword) {
            ForgotPasswordView()
                .presentationDetents([.height(230)])
                .presentationBackground(.background)
                /// iOS 26 auto-adopt cornerRadius as devices
                .presentationCornerRadius(isiOS26OrLater ? nil : 30)
        }
        .sheetAlert(
            isPresented: $userNotVerified,
            prominentSymbol: "envelop.badge",
            title: "Email Verification",
            message: "We have sent a verification email to\nyour address. Please check your inbox.",
            primaryButtonTitle: "Verified",
            primaryButtonAction: {
                if let user = Auth.auth().currentUser {
                    try? await user.reload()
                    if user.isEmailVerified {
                        debugPrint("User email verified")
                        userNotVerified = false
                        onSuccessLogin()
                    }
                }
            }
        )
        .customAlert($alert)
        .focused($isFocused)
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    var isSignInButtonEnabled: Bool {
        !email.isEmpty && !password.isEmpty
    }

    private func login() async {
        do {
            let auth = Auth.auth()
            let result = try await auth.signIn(
                withEmail: email,
                password: password
            )
            if result.user.isEmailVerified {
                /// success login
                onSuccessLogin()
            } else {
                /// in case email is lost
                try await result.user.sendEmailVerification()
                userNotVerified = true
            }
        } catch {
            alert.message = error.localizedDescription
            alert.show = true
        }
    }
}
