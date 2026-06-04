//
//  CustomTextFieldMenuActionsView.swift
//  animation
//
//  Learning point
//  ──────────────
//  iOS 18's new `.menu(...)` modifier on `TextField` lets you ADD
//  custom items to the edit menu (the popup that appears on
//  text-selection long-press). This file shows two:
//    • **Uppercased** — replace the selection with its uppercase.
//    • **Replaced** — replace the selection with a fixed string
//      ("Nanachi") and re-select the inserted text.
//
//  How `TextFieldAction` works
//  ───────────────────────────
//  Each `TextFieldAction { _, textField in ... }` closure receives
//  the underlying `UITextField` (project's bridged type or iOS 18's
//  internal handle). From there you can:
//    • Read the selected range: `textField.selectedTextRange`
//    • Read the selected substring: `textField.text(in: range)`
//    • Replace selection: `textField.replace(range, withText:)`
//    • Compute new positions: `textField.position(from:offset:)`
//    • Build a new range: `textField.textRange(from:to:)`
//
//  This is the same `UITextInput` API SwiftUI uses internally —
//  precise carat / range manipulation that ordinary
//  `@Binding<String>` mutations CAN'T express (you'd lose
//  selection state).
//
//  Why preserve the selection after replace?
//  ─────────────────────────────────────────
//  After a replace, iOS resets the carat to the END of the
//  inserted text. For an "Uppercased" action, the user expects to
//  STILL have the same text selected (just in uppercase) so they
//  can chain another action. We restore selection by storing the
//  original range and reapplying it via `selectedTextRange =`.
//
//  For "Replaced" the original range is now invalid (the inserted
//  string has different length), so we recompute:
//
//      let start = position(from: range.start, offset: 0)
//      let end   = position(from: range.start, offset: replacement.count)
//      selectedTextRange = textRange(from: start, to: end)
//
//  Why `showSuggestions: false`?
//  ─────────────────────────────
//  iOS 18 by default shows AI-driven autocomplete suggestions in
//  the same menu. Setting `showSuggestions: false` removes them
//  so only our custom actions appear.
//
//  Key APIs
//  ────────
//  • `.menu(showSuggestions: false) { TextFieldAction(title:) { ... } }` —
//    iOS 18 entry point.
//  • `UITextInput.selectedTextRange` / `replace(_:withText:)` /
//    `position(from:offset:)` / `textRange(from:to:)` — full
//    selection control.
//
//  How to apply
//  ────────────
//  Use whenever your app has text-manipulation conventions worth
//  exposing inline: word case toggles, autoformatting, smart
//  quotes, link/markdown wrapping, signatures. Each lives in a
//  short closure with `selectedTextRange` as the input.
//
//  See also
//  ────────
//  • CustomTextFieldKeyboardsView.swift — sibling demo replacing
//    the system keyboard entirely.
//  • TextFieldSelectionAPIView.swift — iOS 18 SwiftUI-native
//    selection API for `TextEditor` (no UIKit bridging).
//

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
                                   let selectedText = textField.text(in: selectedRange)
                                {
                                    let upperCasedText = selectedText.uppercased()
                                    textField.replace(selectedRange, withText: upperCasedText)

                                    textField.selectedTextRange = selectedRange
                                }
                            }

                            TextFieldAction(title: "Replaced") { _, textField in
                                if let selectedRange = textField.selectedTextRange {
                                    let replacementText = "Nanachi"

                                    textField.replace(selectedRange, withText: replacementText)

                                    if let start = textField.position(from: selectedRange.start, offset: 0),
                                       let end = textField.position(from: selectedRange.start, offset: replacementText.count)
                                    {
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
