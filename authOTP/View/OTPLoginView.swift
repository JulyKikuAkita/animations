//
//  OTPLoginView.swift
//  animation
//
//  Created on 8/28/25.

import SwiftUI

struct OTPLoginView: View {
    var onComplete: () -> Void
    /// View properties
    @State private var mobileNumber: String = ""
    @State private var countryCode: Country?
    @State private var showVerificationView: Bool = false
    @FocusState private var isFocused: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Welcome Back")
                    .font(.largeTitle)
                Text("Please Verify your mobile number to continue.")
                    .font(.callout)
            }
            .fontWeight(.medium)
            .padding(.top, 5)

            HStack(spacing: 8) {
                Group {
                    CountryCodePickerView(selection: $countryCode)

                    HStack(spacing: 5) {
                        Image(systemName: "phone.fill")
                            .font(.callout)
                            .foregroundStyle(.gray)
                            .frame(width: 30)

                        TextField("Mobile Number", text: $mobileNumber)
                            .textContentType(.telephoneNumber)
                            .keyboardType(.phonePad)
                    }
                    .padding(.horizontal, 12)
                }
                .frame(height: 50)
                .background(.ultraThinMaterial)
                .clipShape(.capsule)
            }
            .padding(.top, 10)

            Button {
                showVerificationView = true
            } label: {
                Text("Get One time passcode")
                    .font(.callout)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .tint(.primary)
            .disabled(mobileNumber.isEmpty)

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
        .padding([.horizontal, .top], 20)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background {
            Color.clear
                .contentShape(.rect)
                .onTapGesture {
                    isFocused = false
                }
        }
        .focused($isFocused)
        .sheet(isPresented: $showVerificationView) {
            OTPVerificationView(fullNumber: fullMobileNumber, onComplete: onComplete)
        }
    }

    var fullMobileNumber: String {
        if let dialCode = countryCode?.dialCode {
            return dialCode + mobileNumber
        }
        return ""
    }
}

#Preview {
    OTPLoginView {}
}
