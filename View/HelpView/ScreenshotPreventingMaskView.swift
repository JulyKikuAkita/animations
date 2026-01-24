//
//  ScreenshotPreventingMaskView.swift
//  animation
//
//  Created on 1/24/26.
import SwiftUI

/// A secure `UITextField` hides its contents during screenshots by rendering
/// text inside a private sublayer (backed by `UITextLayoutCanvasView`) whose
/// contents are automatically blanked by the system.
///
/// This helper walks the text field’s sublayers to locate that internal
/// rendering layer so we can apply a background color to it, ensuring the
/// masked area fully covers the underlying SwiftUI content.
///
struct ScreenshotPreventingDemoView: View {
    @State private var preventScreenshot: Bool = false
    var body: some View {
        NavigationStack {
            List {
                Section("API Key") {
                    Text("1234123412341234")
                        .monospaced()
                }

                Section("Recover Key") {
                    Text("56780234-abcd")
                        .monospaced()
                }

                Toggle("Prevent Screenshot", isOn: $preventScreenshot)
            }
            .navigationTitle("Confidential Data")
        }
        .screenshotPreventingMask(preventScreenshot)
        .background {
            ContentUnavailableView(
                "Not Allowed",
                systemImage: "iphone.slash",
                description: Text("Taking screenshot is not allowed for security reasons.")
            )
        }
    }
}

extension View {
    func screenshotPreventingMask(_ isEnabled: Bool) -> some View {
        mask {
            Group {
                if isEnabled {
                    ScreenshotPreventingMask()
                } else {
                    Rectangle()
                }
            }
            /// if view is navigation stack/tabView
            .ignoresSafeArea()
        }
    }
}

/// -> use secure text field as a mask since when we try to take screenshot of a secure text field, the contents are automatically hidden
/** for example:
 content
  .mask {
     SecureField("", text: .constant("123123"))
         .frame(maxWidth: .infinity, maxHeight: .infinity)
         .contentShape(.rect)
 }
  */
/// the SecureField size only limit to content size thus
/// utilize UIViewRepresentable, which takes all available space,  to mimic a custom UITextField
struct ScreenshotPreventingMask: UIViewRepresentable {
    func makeUIView(context _: Context) -> UIView {
        let view = UITextField()
        view.isSecureTextEntry = true
        view.text = ""
        view.isUserInteractionEnabled = false

        if let autoHideLayer = findAutoHideLayer(view: view) {
            autoHideLayer.backgroundColor = UIColor.white.cgColor
        } else {
            /// fallback:  last view is always the UITextLayoutCanvasView
            view.layer.sublayers?.last?.backgroundColor = UIColor.white.cgColor
        }
        return view
    }

    func updateUIView(_: UIView, context _: Context) {}

    /// since UITextField content is managed by a hidden layer (opacity/alpha = 0) UITextLayoutCanvasView
    /// locating the sublayer and add background to it
    func findAutoHideLayer(view: UIView) -> CALayer? {
        if let layers = view.layer.sublayers {
            if let layer = layers.first(where: { layer in
                layer.delegate.debugDescription.contains("UITextLayoutCanvasView")
            }) {
                return layer
            }
        }
        return nil
    }
}
