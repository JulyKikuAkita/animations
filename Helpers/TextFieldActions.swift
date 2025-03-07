//
//  TextFieldActions.swift
//  animation

import SwiftUI

extension TextField {
    /// showSuggestions: Bool = true -> change to binding for dynamic updates
    @ViewBuilder
    func menu(showSuggestions: Bool = true, @TextFieldActionBuilder actions: @escaping () -> [TextFieldAction]) -> some View {
        self
            .background(
                TextFieldActionHelper(showSuggestions: showSuggestions, actions: actions())
            )
            .compositingGroup() /// group background + textfield in one view, help us to find associated textfield when traverse superview
    }
}

struct TextFieldAction {
    var title: String
    var action: (NSRange, UITextField) -> ()
}

@resultBuilder
struct TextFieldActionBuilder {
    static func buildBlock(_ components: TextFieldAction...) -> [TextFieldAction] {
        components.compactMap({ $0 })
    }
}

fileprivate struct TextFieldActionHelper: UIViewRepresentable {
    var showSuggestions: Bool
    var actions: [TextFieldAction]

    func makeUIView(context: Context) -> some UIView {
        let view =  UIView(frame: .zero)
        view.backgroundColor = .clear

        DispatchQueue.main.async {
            if let textField = view.superview?.superview?.subviews.last?.subviews.first as? UITextField {
                context.coordinator.originalDelegate = textField.delegate
                textField.delegate = context.coordinator
            }
        }

        return view
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: TextFieldActionHelper
        init(parent: TextFieldActionHelper) {
            self.parent = parent
        }

        var originalDelegate: UITextFieldDelegate?

        func textFieldDidChangeSelection(_ textField: UITextField)  {
            originalDelegate?.textFieldDidChangeSelection?(textField)
        }

        func textField( _ textField: UITextField, editMenuForCharactersIn range: NSRange, suggestedActions: [UIMenuElement]) -> UIMenu? {
            var actions: [UIMenuElement] = []
            var customActions = parent.actions.compactMap { item in
                let action = UIAction(title: item.title) { _ in
                    item.action(range, textField)
                }
                return action
            }

            if parent.showSuggestions {
                actions = customActions + suggestedActions
            } else {
                actions = customActions
            }

            let menu = UIMenu(children: actions)
            return menu
        }
    }
}
