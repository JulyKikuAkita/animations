//
//  ForgotPasswordView.swift
//  animation
//
import SwiftUI

struct ForgotPasswordView: View {
    @State private var emailAddress: String = ""
    @State private var isPerforming: Bool = false
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Forgot Password")
                    .font(.title)

                Text("Don't worry. We'll send you a link to reset it.")
                    .textScale(.secondary)
                    .foregroundStyle(.gray)
            }
            .fontWeight(.medium)

            IconTextField(hint: "Email Address", symbol: "envelop", value: $emailAddress)
                .padding(.top, 10)

            TaskButton(title: "Send Reset Link") {} onStatusChange: { isLoading in
                isPerforming = isLoading
            }
            .disabled(emailAddress.isEmpty)
            .padding(.top, 5)
        }
        .padding(.horizontal, 20)
        .padding(.top, 25)
        .allowsHitTesting(!isPerforming)
        .opacity(isPerforming ? 0.7 : 1)
    }
}
