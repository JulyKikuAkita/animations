//
//  TagFieldView.swift
//  animation
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
        /// this will be called when keyboard back button is pressed
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
