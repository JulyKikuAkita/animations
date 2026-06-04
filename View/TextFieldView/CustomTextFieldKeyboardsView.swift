//
//  CustomTextFieldKeyboardsView.swift
//  animation
//
//  Learning point
//  ──────────────
//  Wire up a CUSTOM SwiftUI keyboard view (not iOS's
//  `.keyboardType(.numberPad)`) that appears in place of the system
//  keyboard whenever a `TextField` is focused. Useful for app-
//  specific input pads — currency, calculator, OTP, custom emoji
//  pickers — where the system keyboard either lacks the buttons
//  you need or is visually inconsistent with your design.
//
//  The composition happens in two pieces (both project-local):
//    1. **`CustomTextFieldWithKeyboard`** (referenced here) —
//       wraps a `TextField` and overlays a `keyboard` view at the
//       bottom of the screen, gated by the textfield's
//       `@FocusState`. Defined elsewhere in the project.
//    2. **`CustomKeyboardView`** (this file) — a 3-column
//       `LazyVGrid` of digit buttons + a backspace + a confirm.
//       Owns the binding to `text` and to the parent's `isActive`
//       focus, so it can mutate the text and dismiss itself.
//
//  How button taps update text
//  ───────────────────────────
//  Each `ButtonView` switches on its raw value:
//    • Digits 0–9 → `text += value`
//    • `delete.backward.fill` → `text.removeLast()` (guarded for
//      empty)
//    • `checkmark.circle.fill` → `isActive = false` (dismisses)
//
//  Why `@FocusState.Binding` instead of a plain `Bool`?
//  ────────────────────────────────────────────────────
//  `@FocusState.Binding` lets the keyboard write into the parent's
//  focus token directly. A normal `@Binding<Bool>` would require a
//  separate `.onChange` hook to translate the bool flip back into
//  `isActive` — more code and a subtle one-frame lag.
//
//  Why a `LazyVGrid` instead of nested HStacks?
//  ────────────────────────────────────────────
//  Three columns × four rows = 12 cells. `LazyVGrid` lays them out
//  declaratively in one block. With `GridItem(spacing: 0)` and
//  `spacing: 15` between rows, the layout matches typical iOS
//  numpad spacing without manual padding gymnastics.
//
//  Key APIs
//  ────────
//  • `@FocusState` + `@FocusState.Binding` — bridge focus state
//    across view boundaries.
//  • `LazyVGrid(columns:spacing:)` — declarative grid for keypads.
//  • `.background(.shadow(.drop(...)))` — `ShapeStyle.shadow(.drop)`
//    (iOS 16+) is the recipe for a clean drop shadow on a
//    background fill, no `compositingGroup` needed.
//
//  How to apply
//  ────────────
//  Use whenever the system keyboard is the wrong tool: in-app
//  emoji pickers, currency pads, gamepad-like input, command
//  palettes. The pattern (overlay a custom view, drive it from
//  `@FocusState`, mutate `@Binding<String>`) generalises to
//  anything that reads or writes text.
//
//  See also
//  ────────
//  • View/Sheet/DynamicFloatingSheetsiOS18View.swift — sister
//    custom-keypad pattern inside a sheet.
//  • CustomTextFieldMenuActionsView.swift — sibling demo for
//    `.menu(...)` action customisation on the system keyboard.
//

import SwiftUI

struct CustomTextFieldKeyboardsDemoView: View {
    @State private var text: String = ""
    @FocusState private var isActive: Bool
    var body: some View {
        NavigationStack {
            CustomTextFieldWithKeyboard {
                TextField("Number Pad", text: $text)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 15)
                    .frame(width: 150)
                    .background(.fill, in: .rect(cornerRadius: 12))
                    .focused($isActive)

            } keyboard: {
                CustomKeyboardView(text: $text, isActive: $isActive)
            }
//            .navigationTitle("Custom Keyboard")
        }
    }
}

struct CustomKeyboardView: View {
    @Binding var text: String
    @FocusState.Binding var isActive: Bool
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(spacing: 0), count: 3), spacing: 15) {
            ForEach(1 ... 9, id: \.self) { index in
                buttonView("\(index)")
            }

            buttonView("delete.backward.fill", isImage: true)
            buttonView("0")
            buttonView("checkmark.circle.fill", isImage: true)
        }
        .padding(15)
        .background(.background.shadow(.drop(color: .black.opacity(0.08), radius: 5, x: 0, y: -5)))
    }

    @ViewBuilder
    func buttonView(_ value: String, isImage: Bool = false) -> some View {
        Button {
            if isImage {
                /// delete  the last input character
                if value == "delete.backward.fill", !text.isEmpty {
                    text.removeLast()
                }

                // Close keyboard
                if value == "checkmark.circle.fill" {
                    isActive = false
                }
            } else {
                text += value
            }
        } label: {
            Group {
                if isImage {
                    Image(systemName: value)
                } else {
                    Text(value)
                }
            }
            .font(.title3)
            .fontWeight(.semibold)
            .frame(width: 50, height: 50)
            .background {
                if !isImage {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.background.shadow(.drop(color: .black.opacity(0.08), radius: 3, x: 0, y: 0)))
                }
            }
            .foregroundStyle(Color.primary)
        }
    }
}

#Preview {
    CustomTextFieldKeyboardsDemoView()
}
