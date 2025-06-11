//
//  SimpleTextField.swift
//  animation

import SwiftUI

struct SimpleTextFieldDemoView: View {
    @State private var username: String = ""

    var body: some View {
        NavigationStack {
            VStack {
                SimpleTextField(
                    hint: "Enter username",
                    disallowedCharacters: allowUnderscore,
                    value: $username
                ) { textField, errorMessage in
                    ZStack(alignment: .bottomLeading) {
                        let isEmpty = errorMessage.isEmpty

                        textField
                            .padding(.horizontal, 15)
                            .padding(.vertical, 12)
                            .background {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.gray.opacity(0.2))
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray, lineWidth: 1)
                            )

                        if !isEmpty {
                            Text("Username contains invalid \(errorMessage) characters.")
                                .font(.caption2)
                                .foregroundStyle(.gray)
                                .offset(y: 25)
                                .transition(.blurReplace)
                        }
                    }
                    .animation(.smooth, value: errorMessage)
                }
            }
            .padding(15)
            .navigationTitle(Text("Login"))
        }
    }

    var allowUnderscore: CharacterSet {
        var chars = CharacterSet.letters.inverted
        chars.remove("_")
        return chars
    }
}

struct SimpleTextField<Content: View>: View {
    var hint: String
    var disallowedCharacters: CharacterSet
    @Binding var value: String
    @ViewBuilder var content: (TextField<Text>, String) -> Content
    /// View Properties
    @State private var errorMessage: String = ""
    var body: some View {
        content(
            TextField(hint, text: $value),
            errorMessage
        )
        .onChange(of: value) { oldValue, newValue in
            let restrictedCharacters = newValue.unicodeScalars.filter { disallowedCharacters.contains($0) }

            if !restrictedCharacters.isEmpty {
                value.unicodeScalars.removeAll(where: { !disallowedCharacters.contains($0) })
                errorMessage = "\(restrictedCharacters)"
            } else {
                /// clear error message when typing new non- restricted characters
                if oldValue.unicodeScalars.contains(where: { disallowedCharacters.contains($0) }) {
                    errorMessage = ""
                }
            }
        }
    }
}

#Preview {
    SimpleTextFieldDemoView()
}
