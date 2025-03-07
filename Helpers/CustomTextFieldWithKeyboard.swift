//
//  CustomTextFieldWithKeyboard.swift
//  animation
// Using the UIHostingController to easily retrieve the associated UITextField when view has been created
// and we can use any native SwiftUI textField feature as usual
// since we are only replacing the input views
import SwiftUI

struct CustomTextFieldWithKeyboard<TextField: View, Keyboard: View>: UIViewControllerRepresentable {
    @ViewBuilder var textField: TextField
    @ViewBuilder var keyboard: Keyboard

    func makeUIViewController(context: Context) -> UIHostingController<TextField> {
        let controller = UIHostingController(rootView: textField)
        controller.view.backgroundColor = .clear

        DispatchQueue.main.async {
            if let textField = controller.view.allSubviews.first(where: { $0 is UITextField
                }) as? UITextField, textField.inputView == nil { /// ensure only add input view to the textfield once
                let inputController = UIHostingController(rootView: keyboard)
                inputController.view.backgroundColor = .clear
                inputController.view.frame = .init(
                    origin: .zero,
                    size: inputController.view.intrinsicContentSize)
                textField.inputView = inputController.view
                textField.reloadInputViews()
            }
        }

        return controller
    }

    func updateUIViewController(_ uiViewController: UIHostingController<TextField>, context: Context) {
    }

    /// ensure view wrapper takes up only the necessary space, rather than the entire available space
    func sizeThatFits(_ proposal: ProposedViewSize, uiViewController: UIHostingController<TextField>, context: Context) -> CGSize? {
        return uiViewController.view.intrinsicContentSize
    }
}

/// Finding UITextField from the UIHosting Controller
fileprivate extension UIView {
    var allSubviews: [UIView] {
        return self.subviews.flatMap({ [$0] + $0.allSubviews })
    }
}
