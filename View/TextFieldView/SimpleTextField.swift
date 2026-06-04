//
//  SimpleTextField.swift
//  animation
//
//  Learning point
//  ──────────────
//  Reusable text-field wrapper that REJECTS disallowed characters
//  (typed or pasted) and surfaces an error message describing the
//  rejected characters. Demo enforces "letters and underscore
//  only" — typing `!` or pasting "abc 123" results in those
//  characters being stripped and the message
//  "Username contains invalid `!` characters." appearing.
//
//  Three reusable mechanics
//  ────────────────────────
//    1. **`CharacterSet` + `unicodeScalars` filtering** —
//       the cleanest way to express "what's allowed":
//          var chars = CharacterSet.letters.inverted
//          chars.remove("_")     // and underscore
//       Pass that into the wrapper as `disallowedCharacters`.
//    2. **Trailing closure for layout** — `content: (TextField, String) -> Content`
//       gives the caller the underlying `TextField` AND current
//       error message, letting them style both freely (border,
//       background, error label position) without the wrapper
//       hard-coding any visual style.
//    3. **Stripping vs preventing** — on every `onChange` we
//       remove the offending characters from `value` AFTER the
//       fact. This works for both typing AND paste in one
//       handler — paste triggers the same `onChange`. Trying to
//       prevent the change before it lands is much more code
//       (UIViewRepresentable + delegate methods).
//
//  Subtle behaviour
//  ────────────────
//  When the user TYPES an invalid character, `errorMessage`
//  shows; when they type a VALID character afterward, we clear
//  the error only if the OLD value also contained an invalid
//  character (i.e. transitioning from invalid → valid edit).
//  This avoids flickering the error away on every valid
//  keystroke when the previous keystroke was already valid.
//
//  Key APIs
//  ────────
//  • `CharacterSet.letters.inverted` — "everything except letters."
//  • `String.unicodeScalars.removeAll(where:)` — strip code
//    points by predicate.
//  • Generic `@ViewBuilder content:` parameter — let callers
//    own the layout.
//  • `.transition(.blurReplace)` — soft fade for the error label.
//
//  How to apply
//  ────────────
//  Use whenever you need server-validation parity in the UI:
//  usernames, file names, room codes, slugs. Compose with the
//  caller's own validation summary (e.g. "min 3 chars") for full
//  inline form validation.
//
//  See also
//  ────────
//  • View/Card/CardValidationView.swift — credit-card field with
//    similar character filtering + format inference.
//  • CustomTextFieldMenuActionsView.swift — iOS 18 selection
//    manipulation API for richer transformations.
//

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
