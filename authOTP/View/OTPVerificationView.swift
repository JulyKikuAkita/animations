//
//  OTPVerificationView.swift
//  authOTP
//
//  Created on 8/28/25.

import SwiftUI

struct OTPVerificationView: View {
    var fullNumber: String
    @Environment(\.dismiss) var dismiss
    /// View properties
    @State private var isOTPSent: Bool = false
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
                }
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
            guard !isOTPSent else { return }
            do {
                isOTPSent = true
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
        .animation(.snappy(duration: 0.25, extraBounce: 0), value: isOTPSent)
    }
}

#Preview {
    OTPVerificationView(fullNumber: "123")
}
