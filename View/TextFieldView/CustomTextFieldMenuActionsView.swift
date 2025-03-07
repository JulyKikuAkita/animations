//
//  CustomTextFieldMenuActionsView.swift
//  animation
//  iOS 18

import SwiftUI

struct CustomTextFieldMenuActionsDemoView: View {
    @State private var message: String = ""
    var body: some View {
        NavigationStack {
            List {
                Section("TextField") {
                    TextField("Message", text: $message)
                        .menu(showSuggestions: false) {
                            TextFieldAction(title: "Uppercased") { _, textField in
                                if let selectedRange = textField.selectedTextRange,
                                   let selectedText = textField.text(in: selectedRange) {
                                    let upperCasedText = selectedText.uppercased()
                                    textField.replace(selectedRange, withText: upperCasedText)

                                    textField.selectedTextRange = selectedRange
                                }
                            }

                            TextFieldAction(title: "Replaced") { range, textField in
                                if let selectedRange = textField.selectedTextRange {
                                    let replacementText = "Nanachi"

                                    textField.replace(selectedRange, withText: replacementText)

                                    if let start = textField.position(from: selectedRange.start, offset: 0),
                                       let end = textField.position(from: selectedRange.start, offset: replacementText.count) {
                                        textField.selectedTextRange = textField.textRange(from: start, to: end)
                                    }
                                }
                            }
                        }
                }

                Section {
                    Text(message)
                }

            }
            .navigationTitle("Custom TextField Menu")
        }
    }
}

#Preview {
    CustomTextFieldMenuActionsDemoView()
}
