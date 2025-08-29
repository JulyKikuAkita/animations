//
//  OTPVerificationView.swift
//  authOTP
//
//  Created on 8/28/25.

import FirebaseAuth
import SwiftUI

struct OTPVerificationView: View {
    var fullNumber: String
    var onComplete: () -> Void
    @Environment(\.dismiss) var dismiss
    /// View properties
    @State private var isOTPSent: Bool = false
    @State private var isOTPTaskTrigger: Bool = false
    @State private var otpCode: String = ""
    @State private var alertMessage: String = ""
    @State private var showAlert: Bool = false
    @State private var authID: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            if isOTPSent {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Verification")
                        .font(.largeTitle)

                    HStack(spacing: 4) {
                        Text("Enter the 6-digit code.")
                            .font(.callout)
                    }
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .overlay(alignment: .trailing) {
                        Button("", systemImage: "xmark.circle.fill") { dismiss() }
                            .font(.title)
                            .tint(.gray)
                            .offset(x: 10, y: -15)
                    }
                    .padding(.top, 10)

                    /// Firebase send 6 digit code
                    VerificationTextField(
                        type: .six,
                        showsToolbar: false,
                        value: $otpCode,
                        onChange: { code in
                            if code.count == 6 {
                                isFocused = false
                                do {
                                    let credential = PhoneAuthProvider.provider().credential(
                                        withVerificationID: authID,
                                        verificationCode: code
                                    )
                                    let result = try await Auth.auth().signIn(with: credential)
                                    debugPrint("Sign in with credential: \(result)")
                                    dismiss()
                                    try? await Task.sleep(for: .seconds(0.25)) /// wait for sheet animaiton
                                    onComplete()
                                    return .valid
                                } catch {
                                    isFocused = true
                                    return .invalid
                                }
                            }
                            return .typing
                        }
                    )
                    .allowsHitTesting(false)
                    .padding(.top, 12)
                }
                .padding(20)
                .geometryGroup()
                .transition(.blurReplace)
            } else {
                VStack(spacing: 12) {
                    /// Creating a looping animation
                    let symbols = ["iphone", "ellipsis.message.fill", "paperplane.fill"]
                    PhaseAnimator(symbols) { symbol in
                        Image(systemName: symbol)
                            .font(.system(size: 100))
                            .contentTransition(.symbolEffect)
                            .frame(width: 150, height: 150)
                    } animation: { _ in
                        .linear(duration: 1.2)
                    }
                    .frame(height: 150)

                    Text("Sending verification Code...")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                .geometryGroup()
                .transition(.blurReplace)
            }
        }
        .presentationBackground(.background)
        .presentationDetents([.height(190)])
        .presentationCornerRadius(isiOS26OrLater ? nil : 30)
        .interactiveDismissDisabled()
        .task {
            guard !isOTPTaskTrigger else { return }
            isOTPTaskTrigger = true
            do {
                try await sendOTP() // comment out this line for preview
                isOTPSent = true
                isFocused = true
            } catch {
                debugPrint(error.localizedDescription)
                alertMessage = error.localizedDescription
                showAlert = true
            }
        }
        .animation(.snappy(duration: 0.25, extraBounce: 0), value: isOTPSent)
        .focused($isFocused)
        .alert("Something Went Wrong", isPresented: $showAlert) {
            Button("Dismiss", role: .cancel) {
                /// Closing the verification sheet
                dismiss()
            }
        } message: {
            Text(alertMessage)
        }
    }

    // will crash preview
    private func sendOTP() async throws {
        let provider = PhoneAuthProvider.provider()
        let authID = try await provider.verifyPhoneNumber(fullNumber)
        self.authID = authID
    }
}

#Preview {
    OTPVerificationView(fullNumber: "123", onComplete: {})
}
