//
//  TagFieldView.swift
//  animation
//
//  Learning point
//  ──────────────
//  Native-feeling tag input field (think: GitHub label picker, mail
//  recipient field). Each tag is its own `TextField`-shaped row laid
//  out via `TagLayout` (flow-wrap). Three keyboard interactions matter:
//
//    1. **Comma → commit** — typing "," ends the current tag and inserts
//       a fresh empty one. Implemented in `onChange(of: tag.value)`:
//       strip the trailing comma, append a new `Tag(value: "")`.
//    2. **Backspace on empty → delete previous** — the magic part. Pure
//       SwiftUI `TextField` doesn't expose backspace-on-empty events, so
//       we drop down to UIKit (`BackSpaceListenerTextField`,
//       `UIViewRepresentable`) and override `UITextField.deleteBackward`.
//    3. **Keyboard dismiss → seal current tag** — listening to
//       `UIResponder.keyboardWillHideNotification` ensures any in-flight
//       text gets committed when the user taps outside.
//
//  Why a `UIViewRepresentable` for a TextField?
//  ────────────────────────────────────────────
//  iOS's SwiftUI `TextField` doesn't deliver a "user pressed backspace
//  in an already-empty field" event — that signal only exists on
//  `UITextField.deleteBackward`. Subclassing UIKit and bridging it via
//  `UIViewRepresentable` is the common (and idiomatic) escape hatch
//  whenever you need keyboard-event granularity SwiftUI doesn't surface.
//
//  Bonus: `canPerformAction(_:withSender:)` is overridden to return
//  `false` so the standard cut/copy/paste/share menu doesn't appear on
//  long-press. Tags are short labels — the menu is noise.
//
//  `isInitial` flag — what is it for?
//  ──────────────────────────────────
//  `Tag.isInitial` distinguishes "freshly inserted empty placeholder
//  awaiting tap-to-edit" from "actively-being-typed empty tag." Used to
//  gate focus and tap targets so the placeholder doesn't auto-focus on
//  every state change.
//
//  Key APIs
//  ────────
//  • `UIViewRepresentable` + `UITextField` subclass — keyboard event
//    bridge.
//  • `UITextField.deleteBackward` override — capture backspace.
//  • `sizeThatFits(_:uiView:context:)` — return `intrinsicContentSize`
//    so the bridged textfield doesn't expand to fill its container.
//  • `NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)`
//    — react to keyboard dismiss.
//  • `TagLayout` (project-local) — flow layout for the chips row.
//
//  How to apply
//  ────────────
//  Reach for the UIKit bridge any time you need keyboard semantics
//  SwiftUI doesn't expose: backspace on empty, return-key behaviour,
//  inputAccessoryView, custom keyboards. Wrap the minimum necessary in
//  `UIViewRepresentable` and keep all SwiftUI styling outside.
//
//  See also
//  ────────
//  • SelectTagView.swift — non-text-input tag picker.
//  • DynamicTagWidthView.swift — same `TagLayout` flow-wrap idea
//    applied to read-only chips.
//
import SwiftUI

struct TagFieldDemoView: View {
    /// View properties
    @State private var tags: [Tag] = []
    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                VStack {
                    TagField(tags: $tags)
                }
                .padding()
            }
            .navigationTitle("Tag Field")
        }
    }
}

struct TagField: View {
    @Binding var tags: [Tag]
    var body: some View {
        TagLayout { // tagLayout at https://www.youtube.com/watch?v=FzL11vRhzs8j
            ForEach($tags) { $tag in
                TagView(tag: $tag, allTags: $tags)
                    .onChange(of: tag.value) { newValue, _ in
                        if newValue.last == "," {
                            /// removing last comma
                            tag.value.removeLast()
                            /// inserting new tag item
                            if !tag.value.isEmpty {
                                /// Safe check
                                tags.append(.init(value: ""))
                            }
                        }
                    }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 15)
        .background(.bar, in: .rect(cornerRadius: 12))
        .onAppear(perform: {
            /// Initialing tag view
            if tags.isEmpty {
                tags.append(.init(value: "", isInitial: true))
            }
        })
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification), perform: { _ in
            if let lastTag = tags.last, !lastTag.value.isEmpty {
                /// Inserting an empty tag
                tags.append(.init(value: "", isInitial: true))
            }
        })
    }
}

/// Tag view
private struct TagView: View {
    @Binding var tag: Tag
    @Binding var allTags: [Tag]
    @FocusState private var isFocused: Bool
    /// View properties
    @Environment(\.colorScheme) private var colorScheme
    var body: some View {
        BackSpaceListenerTextField(hint: "Tag", text: $tag.value, onBackPressed: {
            if allTags.count > 1 { // keep the first tag
                if tag.value.isEmpty {
                    allTags.removeAll(where: { $0.id == tag.id })
                    // Activating the previously available tag
                    if let lastIndex = allTags.indices.last {
                        allTags[lastIndex].isInitial = false
                    }
                }
            }
        })
        .focused($isFocused)
        .padding(.vertical, 10)
        .padding(.horizontal, isFocused || tag.value.isEmpty ? 0 : 10)
        .background((colorScheme == .dark ? Color.black : Color.white).opacity(isFocused || tag.value.isEmpty ? 0 : 1), in: .rect(cornerRadius: 5))
        .disabled(tag.isInitial)
        .onChange(of: allTags, initial: true) { _, newValue in
            if newValue.last?.id == tag.id,
               !(newValue.last?.isInitial ?? false), !isFocused
            {
                isFocused = true
            }
        }
        .overlay {
            if tag.isInitial {
                Rectangle()
                    .fill(.clear)
                    .contentShape(.rect)
                    .onTapGesture {
                        /// activating only for the last tag
                        if allTags.last?.id == tag.id {
                            tag.isInitial = false
                            isFocused = true
                        }
                    }
            }
        }
        .onChange(of: isFocused) { _, _ in
            if !isFocused {
                tag.isInitial = true
            }
        }
    }
}

private struct BackSpaceListenerTextField: UIViewRepresentable {
    var hint: String = "Tag"
    @Binding var text: String
    var onBackPressed: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeUIView(context: Context) -> CustomTextField {
        let textField = CustomTextField()
        textField.delegate = context.coordinator
        /// Optional
        textField.placeholder = hint
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .words
        textField.backgroundColor = .clear
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textChange(textField:)), for: .editingChanged)
        return textField
    }

    func updateUIView(_: CustomTextField, context _: Context) {}

    func sizeThatFits(_: ProposedViewSize, uiView: CustomTextField, context _: Context) -> CGSize? {
        /// maintain the textfield size rather than taking rest of available space
        uiView.intrinsicContentSize
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var text: String
        init(text: Binding<String>) {
            _text = text
        }

        /// Text change
        @objc
        func textChange(textField: UITextField) {
            text = textField.text ?? ""
        }

        /// closing on pressing return button
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
        }
    }
}

/// Tip: the only reason this UIKit subclass exists.
/// `deleteBackward` is the lowest-level hook for "user just pressed the
/// keyboard's delete key" — it fires even when the field is empty,
/// which `.onChange(of: text)` does NOT (no string change to observe).
/// SwiftUI's `TextField` doesn't expose this signal at all in iOS 17/18,
/// so dropping down to `UITextField` is the only path.
///
/// `canPerformAction` returns `false` to suppress the system edit menu
/// (cut / copy / paste / share). Tags are tiny labels — the menu is
/// visual noise and almost never useful. Remove this override if you
/// actually want copy/paste on tag values.
private class CustomTextField: UITextField {
    open var onBackPressed: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func deleteBackward() {
        /// fires for both "remove a character" and "backspace on empty"
        onBackPressed?()
        super.deleteBackward()
    }

    override func canPerformAction(_: Selector, withSender _: Any?) -> Bool {
        false
    }
}

#Preview {
    TagFieldDemoView()
}
