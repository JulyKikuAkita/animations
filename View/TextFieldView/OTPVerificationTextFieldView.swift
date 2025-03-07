//
//  OTPVerificationTextFieldView.swift
//  animation
//

import SwiftUI

struct OTPVerificationTextFieldDemoView: View {
    @State private var codeFour: String = ""
    @State private var codeSix: String = ""
    var body: some View {
        VStack(spacing: 25) {
            VerificationTextField(type: .four, style: .underlined, value: $codeFour ) { result in
                if result.count < 6 {
                    return .typing
                } else if result == "1234" {
                    return .valid
                } else {
                    return .invalid
                }
            }

            Spacer(minLength: 0)

            VerificationTextField(type: .six, style: .roundedBorder, value: $codeSix) { result in
                if result.count < 6 {
                    return .typing
                } else if result == "12345" {
                    return .valid
                } else {
                    return .invalid
                }
            }

            Spacer(minLength: 0)
        }
    }
}

enum OTPLength: Int, CaseIterable {
    case four = 4
    case six = 6

    var strigValue: String {
        "\(rawValue) Digit"
    }
}

enum TypingState {
    case typing, valid, invalid
}

enum TextFieldStyle: String, CaseIterable {
    case roundedBorder = "RoundedBorder"
    case underlined = "Underlined"
}

struct VerificationTextField: View {
    var type: OTPLength
    var style: TextFieldStyle = .roundedBorder
    @Binding var value: String
    /// Validate code while typing
    var onChange: (String) async -> TypingState
    /// View Properties
    @State private var state: TypingState = .typing
    @State private var invalidTrigger: Bool = false
    @FocusState private var isActive: Bool
    var body: some View {
        HStack(spacing: style == .roundedBorder ? 6 : 10) {
            ForEach(0..<type.rawValue, id: \.self) { index in
                CharacterView(index)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: value)
        .animation(.easeInOut(duration: 0.2), value: isActive)
        .compositingGroup()
        /// invalid code animation
        .phaseAnimator([0, 10, -10, 10, -5, 5, 0], trigger: invalidTrigger, content: { content, offset in
            content
                .offset(x: offset)
        }, animation: { _ in
                .linear(duration: 0.09)
        })
        .background {
            /// non interactive text field view, activate by focus state
            TextField("", text: $value)
                .focused($isActive)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .mask(alignment: .trailing) {
                    Rectangle()
                        .frame(width: 1, height: 1)
                        .opacity(0.01)
                }
                .allowsHitTesting(false)
        }
        .contentShape(.rect)
        .onTapGesture {
            isActive = true
        }
        .onChange(of: value) { oldValue, newValue in
            /// Limiting text length
            value = String(newValue.prefix(type.rawValue))
            Task { @MainActor in
                /// Validation check
                state = await onChange(value)
                if state == .invalid {
                    invalidTrigger.toggle()
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .keyboard) {
                Button("Done") {
                    isActive = false
                }
                .tint(Color.primary)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    @ViewBuilder
    func CharacterView(_ index: Int) -> some View {
        Group {
            if style == .roundedBorder {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor(index), lineWidth: 1.2)
            } else {
                Rectangle()
                    .fill(borderColor(index))
                    .frame(height: 1)
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
        }
        .frame(width: style == .roundedBorder ? 50 :40, height: 50)
        .overlay {
            /// Showing Characters
            let stringValue = string(index)

            if stringValue != "" {
                Text(stringValue)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .transition(.blurReplace)
            }
        }
    }

    func string(_ index: Int) -> String {
        if value.count > index {
            let startIndex = value.startIndex
            let stringIndex = value.index(startIndex, offsetBy: index)

            return String(value[stringIndex])
        }

        return ""
    }

    func borderColor(_ index: Int) -> Color {
        switch state {
            /// Highlight active field when keyboard is active
            case .typing: value.count == index && isActive ? Color.primary : .gray
            case .valid: .green
            case .invalid: .red
        }
    }
}

#Preview {
    OTPVerificationTextFieldDemoView()
}
