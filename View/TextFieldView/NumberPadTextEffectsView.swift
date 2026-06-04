//
//  NumberPadTextEffectsView.swift
//  animation
//
//  Learning point
//  ──────────────
//  Apple-Cash / Venmo-style "Send Money" amount entry: each digit
//  pushes in from the bottom, each delete pushes UP and out, and
//  thousand-separator commas SLIDE between positions instead of
//  appearing/disappearing. The polish comes from one architectural
//  choice — each character is its own identity-stable view, so
//  SwiftUI can animate INDIVIDUAL characters rather than treating
//  the whole `Text("1,234")` as one opaque string.
//
//  Three reusable mechanics
//  ────────────────────────
//    1. **`KeypadValue` model** — splits the displayed amount into
//       a `[Number]` array where each entry has its own UUID.
//       Digits and commas are separate entries, so `ForEach(stackViews)`
//       animates each independently.
//    2. **Asymmetric push transitions** — digits use
//       `.transition(.asymmetric(insertion: .push(from: .bottom),
//       removal: .push(from: .top)))` so the user sees them slide
//       *in* from below the keypad and *out* upward when deleted.
//       Commas use `.contentTransition(.interpolate)` instead.
//    3. **`matchedGeometryEffect` for commas** — commas keep a
//       stable `commaID` (their ordinal among commas, not their
//       string index). So when "1234" → "12345" reshapes from
//       "1,234" to "12,345", the SAME comma view slides from
//       between "1,234" to between "12,345" rather than fading
//       in a new one.
//
//  Why preserve commas in `updateCommas()` instead of rebuilding
//  ─────────────────────────────────────────────────────────────
//  Trivial implementation: re-format on every keystroke and
//  replace the entire `stackViews` array. SwiftUI sees that as
//  removing all old views and inserting all new ones — every
//  digit and comma fades / pushes simultaneously. Looks chaotic.
//
//  This file's approach: only INSERT commas at the right indices
//  WITHOUT touching existing digit views. Each digit's identity
//  (UUID) survives, so they stay in place; only commas animate.
//  Subtle but the visual difference is obvious.
//
//  Why `Text("0")` placeholder uses `.contentTransition(.numericText())`
//  ────────────────────────────────────────────────────────────────────
//  When the input is empty, we show "0" in grey. As soon as the
//  user types, the "0" needs to disappear and "1" needs to slide
//  in. `.contentTransition(.numericText())` animates the "0 → 1"
//  morph as a digit roll. Combined with `.frame(width: value.isEmpty ? nil : 0)`
//  to collapse the placeholder cell, it produces a smooth handoff.
//
//  Why `.buttonRepeatBehavior(.enabled)` on backspace
//  ──────────────────────────────────────────────────
//  iOS 17+ feature: long-press auto-repeats a button's tap action.
//  On the delete button this means hold-to-erase (like the system
//  number pad). Disabled on the "0" key to avoid accidental
//  spam-zero entry.
//
//  Key APIs
//  ────────
//  • `matchedGeometryEffect(id:in:)` — preserve view identity for
//    commas across reformats.
//  • `.transition(.asymmetric(insertion:removal:))` — different
//    enter / exit motions per direction.
//  • `.contentTransition(.numericText())` and `.contentTransition(.interpolate)` —
//    in-place animated text swaps.
//  • `.buttonRepeatBehavior(.enabled)` — iOS 17+ auto-repeat on
//    long press.
//  • `NumberFormatter(numberStyle: .decimal, locale:)` — locale-
//    aware thousand separators (here pinned to "en_US"; swap to
//    `Locale.current` for native formatting).
//
//  How to apply
//  ────────────
//  Use this pattern for any "amount entry" UI: payments, currency,
//  calculator displays, OTP confirms with formatting. The
//  per-character identity model is the architectural lesson —
//  most "animated number text" UIs are one rebuilt string and
//  miss the polish.
//
//  See also
//  ────────
//  • OTPVerificationTextFieldView.swift — sister number-input
//    pattern with fixed-length validation.
//  • CustomTextFieldKeyboardsView.swift — generic custom keyboard
//    template.
//

import SwiftUI

struct KeypadValue {
    var stringValue: String = ""
    var stackViews: [Number] = []

    struct Number: Identifiable {
        var id: String = UUID().uuidString
        var value: String = ""
        var isComma: Bool = false
        /// id for matched gemonetry effect
        var commaID: Int = 0
    }

    mutating func append(_ number: Int) {
        /// do not start with number 0 first or not exceed max number length
        guard !isExceedMaxLength, number == 0 ? !stringValue.isEmpty : true else { return }
        stringValue.append(String(number))
        stackViews.append(.init(value: String(number)))
        updateCommas()
    }

    mutating func removeLast() {
        guard !stringValue.isEmpty else { return }
        stringValue.removeLast()
        stackViews.removeLast()
        updateCommas()
    }

    mutating func updateCommas() {
        guard let number = Int(stringValue) else { return }

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: localFormat)

        if let formattedNumber = formatter.string(from: .init(value: number)) {
            /// remove existing commas
            stackViews.removeAll(where: \.isComma)

            let stackWithCommas = formattedNumber.compactMap {
                let value = String($0)
                return Number(value: value, isComma: value == ",")
            }

            // Tip: insert commas WITHOUT replacing the digit array.
            // `stackViews` retains its existing `Number(UUID)` digits;
            // we only `.insert` new comma entries at the right indices.
            // The `commaID` is the comma's ordinal position among
            // commas (0, 1, 2, ...), used as the matchedGeometry id
            // so the SAME comma view slides between positions as the
            // amount changes (e.g. "1,234" → "12,345" reuses the
            // single comma with id=0).
            let onlyCommaArray = stackWithCommas.filter(\.isComma)
            for index in stackWithCommas.indices {
                let placeHolder = stackWithCommas[index]
                let commaIndex = onlyCommaArray.firstIndex(where: { $0.id == placeHolder.id }) ?? 0
                if placeHolder.isComma {
                    stackViews.insert(.init(value: ",", isComma: true, commaID: commaIndex), at: index)
                }
            }
        }
    }

    var isEmpty: Bool {
        stringValue.isEmpty
    }

    var isExceedMaxLength: Bool {
        stringValue.count >= 11
    }

    var intValue: Int {
        Int(stringValue) ?? 0
    }

    var localFormat: String {
        "en_US"
    }
}

struct NumberPadTextEffectsViewDemoView: View {
    /// View Properties
    @State private var value: KeypadValue = .init()
    @Namespace private var animation
    var body: some View {
        VStack(spacing: 20) {
            Text("Send Money")
                .font(.largeTitle.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 5)

            VStack(spacing: 6) {
                Image(.fox)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipShape(.circle)

                Text("Fox")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .frame(maxHeight: .infinity)

            HStack(spacing: 2) {
                animatedNumberTextView()
            }
            .frame(height: 50)
            .padding(.bottom, 30)

            customNumberKeypad()
        }
        .fontDesign(.rounded)
        .padding(15)
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    func animatedNumberTextView() -> some View {
        HStack(spacing: 2) {
            Text("$")

            Text(value.isEmpty ? "0" : "")
                .frame(width: value.isEmpty ? nil : 0)
                .contentTransition(.numericText())
                .padding(.leading, 3)

            ForEach(value.stackViews) { number in
                Group {
                    if number.isComma {
                        Text(",")
                            .contentTransition(.interpolate)
                            .matchedGeometryEffect(id: number.commaID, in: animation)
                    } else {
                        Text(number.value)
                            .contentTransition(.interpolate)
                            .transition(.asymmetric(insertion: .push(from: .bottom),
                                                    removal: .push(from: .top)))
                    }
                }
            }
        }
    }

    @ViewBuilder
    func customNumberKeypad() -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(), count: 3)) {
            ForEach(1 ... 9, id: \.self) { index in
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        value.append(index)
                    }
                } label: {
                    Text("\(index)")
                        .font(.title2.bold())
                        .frame(maxWidth: .infinity)
                        .frame(height: 70)
                        .contentShape(.rect)
                }
            }

            Spacer()

            ForEach(["0", "delete.backward.fill"], id: \.self) { string in
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        if string == "0" {
                            value.append(0)
                        } else {
                            value.removeLast()
                        }
                    }
                } label: {
                    Group {
                        if string == "0" {
                            Text("0")
                        } else {
                            Image(systemName: string)
                        }
                    }
                    .font(.title2.bold())
                    .frame(maxWidth: .infinity)
                    .frame(height: 70)
                    .contentShape(.rect)
                }
                /// long pressed back button to remove input
                .buttonRepeatBehavior(string == "0" ? .disabled : .enabled)
            }
        }
        .buttonStyle(KeypadButtonStyle())
        .foregroundStyle(.white)
    }
}

#Preview {
    NumberPadTextEffectsViewDemoView()
}

struct KeypadButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                RoundedRectangle(cornerRadius: 15)
                    .fill(.gray.opacity(0.2))
                    .opacity(configuration.isPressed ? 1 : 0)
                    .padding(.horizontal, 5)
            }
            .animation(.easeInOut(duration: 0.25), value: configuration.isPressed)
    }
}
