//
//  OTPVerificationTextFieldView.swift
//  animation
//
//  Learning point
//  ──────────────
//  4- or 6-digit OTP / verification field that LOOKS like N
//  separate boxes but is actually ONE invisible `TextField`
//  underneath. The visible boxes are "fake" — they read the
//  shared `value` string and display the matching character.
//  This setup gets you for free:
//    • Native paste support (paste a 6-digit code from SMS).
//    • Native iOS auto-fill of `oneTimeCode` (the keyboard's
//      yellow autofill bar).
//    • Single source of truth (`@Binding var value: String`).
//    • Standard cursor / selection inside the hidden field.
//
//  Three reusable mechanics
//  ────────────────────────
//    1. **Hidden TextField behind visible boxes** —
//       a `TextField` placed in `.background` is masked to a
//       1×1 rect (`.opacity(0.01)`) so it occupies almost no
//       space but still receives focus and pastes. A tap
//       gesture on the box stack sets `isActive = true`,
//       summoning the keyboard.
//    2. **Per-box derived display** — `string(_ index:)` reads
//       the n-th character of `value`. The active index gets
//       a primary border colour; everything else is grey.
//       `.transition(.blurReplace)` softens the digit appear.
//    3. **`.phaseAnimator` for invalid shake** —
//       `[0, 10, -10, 10, -5, 5, 0]` walks the X offset through
//       a damped wobble each time `invalidTrigger` toggles.
//       Native iOS-style wrong-password shake without a
//       custom `Animatable` modifier.
//
//  Why `.textContentType(.oneTimeCode)`
//  ────────────────────────────────────
//  Tells iOS this field expects an SMS one-time code, which
//  enables auto-fill from the system. iOS reads incoming SMS
//  for codes and offers a tap-to-fill in the QuickType bar.
//  Critical for verification UX — without this, users have to
//  manually copy/paste codes.
//
//  Why `.allowsHitTesting(false)` on the hidden TextField
//  ─────────────────────────────────────────────────────
//  We DON'T want the user actually tapping into the 1×1
//  rectangle. They tap on the visible box stack; our explicit
//  `.onTapGesture` sets focus to the hidden field. This keeps
//  the visible boxes feeling like the real input.
//
//  Why `Task { @MainActor in ... }` for validation
//  ───────────────────────────────────────────────
//  `onChange(_:)` is sync. The `onChange` callback the caller
//  provides is `async` (e.g. it might hit the network), so we
//  spawn a `Task` to call it. Result triggers `state` update
//  and conditionally fires `invalidTrigger.toggle()` to start
//  the shake.
//
//  Two visual styles
//  ─────────────────
//  • **`.roundedBorder`** — full bordered boxes, e.g. SMS code
//    or 2FA flows.
//  • **`.underlined`** — minimalist single underline per char,
//    e.g. credit-card CVV style.
//
//  Key APIs
//  ────────
//  • `.textContentType(.oneTimeCode)` + `.keyboardType(.numberPad)` —
//    the OTP autofill combo.
//  • `.phaseAnimator(_:trigger:content:animation:)` (iOS 17+) —
//    sequenced state animations driven by a Boolean ratchet.
//  • `.toolbar { ToolbarItem(placement: .keyboard) { ... } }` —
//    add a "Done" above the keyboard (gated on `showsToolbar`).
//  • `.transition(.blurReplace)` — soft enter for new digits.
//
//  How to apply
//  ────────────
//  Drop in for any verification flow: 2FA, email confirmation
//  codes, PIN entry, recovery codes. The hidden-textfield-with-
//  fake-boxes pattern generalises whenever you want native
//  text-field semantics with a custom visual layout.
//
//  See also
//  ────────
//  • NumberPadTextEffectsView.swift — sister number-input that
//    drives a custom keypad UI (no system keyboard).
//  • CustomTextFieldKeyboardsView.swift — full custom keyboard
//    overlay pattern.
//

import SwiftUI

struct OTPVerificationTextFieldDemoView: View {
    @State private var codeFour: String = ""
    @State private var codeSix: String = ""
    var body: some View {
        VStack(spacing: 25) {
            VerificationTextField(type: .four,
                                  style: .underlined,
                                  showsToolbar: true,
                                  value: $codeFour)
            { result in
                if result.count < 6 {
                    .typing
                } else if result == "1234" {
                    .valid
                } else {
                    .invalid
                }
            }

            Spacer(minLength: 0)

            VerificationTextField(type: .six,
                                  style: .roundedBorder,
                                  showsToolbar: false,
                                  value: $codeSix)
            { result in
                if result.count < 6 {
                    .typing
                } else if result == "12345" {
                    .valid
                } else {
                    .invalid
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
    var showsToolbar: Bool = true
    @Binding var value: String
    /// Validate code while typing
    var onChange: (String) async -> TypingState
    /// View Properties
    @State private var state: TypingState = .typing
    @State private var invalidTrigger: Bool = false
    @FocusState private var isActive: Bool
    var body: some View {
        HStack(spacing: style == .roundedBorder ? 6 : 10) {
            ForEach(0 ..< type.rawValue, id: \.self) { index in
                characterView(index)
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
        .onChange(of: value) { _, newValue in
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
        .modifier(OptionalToolbarModifier(isActive: $isActive, enabled: showsToolbar))
    }

    private struct OptionalToolbarModifier: ViewModifier {
        var isActive: FocusState<Bool>.Binding
        var enabled: Bool

        func body(content: Content) -> some View {
            if enabled {
                content.toolbar {
                    ToolbarItem(placement: .keyboard) {
                        Button("Done") { isActive.wrappedValue = false }
                            .tint(Color.primary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            } else {
                content
            }
        }
    }

    @ViewBuilder
    func characterView(_ index: Int) -> some View {
        Group {
            if style == .roundedBorder {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor(index), lineWidth: 2)
            } else {
                Rectangle()
                    .fill(borderColor(index))
                    .frame(height: 1)
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
        }
        .frame(width: style == .roundedBorder ? 50 : 40, height: 50)
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
        .frame(maxWidth: .infinity)
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
