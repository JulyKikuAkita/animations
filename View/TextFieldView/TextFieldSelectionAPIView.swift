//
//  TextFieldSelectionAPIView.swift
//  animation
//
//  Learning point
//  ──────────────
//  iOS 18's NEW SwiftUI-native text-selection API for `TextEditor`.
//  Before iOS 18, manipulating the cursor or selection from
//  SwiftUI required either:
//    • Bridging to `UITextView` via `UIViewRepresentable`, OR
//    • Using `.menu(...)` on `TextField` (only works on tap).
//  Now there's a clean `selection: Binding<TextSelection?>` you
//  read AND write programmatically.
//
//  Three reusable mechanics
//  ────────────────────────
//    1. **Insertion-point control** — `.init(insertionPoint: Index)`
//       moves the cursor to that String index without selecting
//       anything. "Move to First" / "Move to Last" / "After Hello".
//    2. **Range selection** — `.init(range: Range<String.Index>)`
//       selects text. "Select Hello" highlights `range(of: "Hello")`.
//    3. **Range-aware mutation** — `text.replaceSubrange(range, with: ...)`
//       to splice in new content; remember to RECOMPUTE and reapply
//       the selection because indices shift after a replace.
//
//  Why the workaround `selection: TextSelection? = .init(insertionPoint: "".startIndex)`
//  ────────────────────────────────────────────────────────────────────────────────────
//  See the comment on the property: there's a Swift bug in early
//  iOS 18 where `selection` doesn't update if it starts as `nil`.
//  Initialising with a placeholder insertion point at index 0
//  works around it. Remove this once Apple ships the fix.
//
//  Reading the current selection
//  ─────────────────────────────
//  `TextSelection.indices` is an enum (`.selection(Range)` or
//  `.multiSelection(...)`). The `selectedTextRange` computed
//  property unwraps the common case, returning `nil` when the
//  user only has a cursor (not a range). Pattern:
//
//      if let selection, !selection.isInsertion {
//          if case let .selection(range) = selection.indices {
//              // use `range` here
//          }
//      }
//
//  Why this beats `.menu(...)` on TextField
//  ────────────────────────────────────────
//  • Works on `TextEditor` (multi-line) AND `TextField`.
//  • You can move the cursor PROGRAMMATICALLY (not just from a
//    user tap on a menu).
//  • Pure SwiftUI — no UIKit bridging.
//  • Reactive: `onChange(of: selection)` lets you observe every
//    selection change, including drag-selections.
//
//  Key APIs
//  ────────
//  • `TextEditor(text:selection:)` (iOS 18+) — the new init.
//  • `TextSelection.init(insertionPoint:)` / `.init(range:)` —
//    construct selections.
//  • `TextSelection.indices` (`.selection`, `.multiSelection`) —
//    discriminated union of selection state.
//  • `.onChange(of: selection)` — observe selection changes.
//
//  How to apply
//  ────────────
//  Use whenever your text UI needs to:
//    • Jump the cursor to a specific position (e.g. after a
//      template insertion).
//    • Highlight matched text (search, syntax errors).
//    • Replace selected text smartly (markdown wrapping,
//      formatting buttons in a rich editor).
//
//  See also
//  ────────
//  • CustomTextFieldMenuActionsView.swift — UIKit-bridged
//    selection manipulation via `.menu(...)`.
//  • View/TextEffectView/TagFieldView.swift — uses
//    `UIViewRepresentable` to capture backspace events that
//    SwiftUI doesn't expose.
//

import SwiftUI

@available(iOS 18.0, *)
struct TextFieldSelectionAPIView: View {
    /// View properties
    @State private var text: String = ""
    @State private var selection: TextSelection? = .init(insertionPoint: "".startIndex) // fix selection not updated Swift bug
    var body: some View {
        NavigationStack {
            VStack {
                TextEditor(text: $text, selection: $selection)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 15)
                    .frame(height: 150)
                    .background(.background, in: .rect(cornerRadius: 10))

                VStack(spacing: 15) {
                    HStack(spacing: 20) {
                        Button("Move After Hello World") {
                            if let range = text.range(of: "Hello") {
                                let endIndex = range.upperBound
                                selection = .init(insertionPoint: endIndex)
                            }
                        }

                        Button("Select Hello World") {
                            if let range = text.range(of: "Hello") {
                                selection = .init(range: range)
                            }
                        }
                    }

                    HStack(spacing: 20) {
                        Button("Move to First") {
                            selection = .init(insertionPoint: text.startIndex)
                        }

                        Button("Move to Last") {
                            selection = .init(insertionPoint: text.endIndex)
                        }
                    }

                    if let selectedTextRange, text[selectedTextRange] == "Hello" {
                        Button("Replace with Hi There") {
                            text.replaceSubrange(selectedTextRange, with: "Hi There")
                            // update selection text
                            let startIndex = selectedTextRange.lowerBound
                            let length = "Hi There".count
                            let endIndex = text.index(
                                startIndex,
                                offsetBy: length
                            )
                            let newRange: Range<String.Index> = .init(
                                uncheckedBounds: (startIndex, endIndex)
                            )
                            selection = .init(range: newRange)
                        }
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(15)
            .navigationTitle("Text Selection API")
            .background(.gray.opacity(0.1))
            .onChange(of: selection) { _, newValue in
                if let selection = newValue, !selection.isInsertion {
                    switch selection.indices {
                    case let .selection(range):
                        let selectedText = text[range]
                        print(selectedText)
                    default:
                        print("Others")
                    }
                }
            }
        }
    }

    var selectedTextRange: Range<String.Index>? {
        if let selection, !selection.isInsertion {
            switch selection.indices {
            case let .selection(range):
                return range
            default: return nil
            }
        }

        return nil
    }
}

#Preview {
    if #available(iOS 18.0, *) {
        TextFieldSelectionAPIView()
    } else {
        // Fallback on earlier versions
    }
}
