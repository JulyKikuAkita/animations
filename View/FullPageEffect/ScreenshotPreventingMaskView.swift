//
//  ScreenshotPreventingMaskView.swift
//  animation
//
//  Created on 1/24/26.
//
// SwiftUI learning notes — key takeaways in this file:
//
// 1. `.mask { ... }` keeps only the parts of a view covered by the mask's
//    opaque pixels. If the mask hides its own pixels (as a SecureField does
//    during a screenshot), the masked content is hidden too.
// 2. Extending `View` is the idiomatic way to package a reusable modifier —
//    callers then read like built-in SwiftUI (`.screenshotPreventingMask(...)`).
// 3. When SwiftUI doesn't expose a behavior you need (here: secure-entry
//    screenshot blanking), `UIViewRepresentable` bridges a UIKit view in.
//
import SwiftUI

/// Demo view — toggle the switch, then take a screenshot on a device.
/// The list contents are replaced by the `ContentUnavailableView` placed
/// in `.background` because the mask blanks the foreground in the screenshot.
struct ScreenshotPreventingDemoView: View {
    // `@State` owns a simple value inside this view. Flipping it re-renders
    // the body, which is what drives the mask on/off.
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
        // Custom modifier defined below. Reads top-down like native SwiftUI.
        .screenshotPreventingMask(preventScreenshot)
        // `.background` sits *behind* the masked content. When the mask hides
        // the foreground during a screenshot, this placeholder is what shows.
        .background {
            ContentUnavailableView(
                "Not Allowed",
                systemImage: "iphone.slash",
                description: Text("Taking screenshot is not allowed for security reasons.")
            )
        }
    }
}

// MARK: - Reusable modifier

//
// Takeaway: add custom modifiers via `extension View`. Returning `some View`
// hides the concrete (often messy) type so callers only see "it's a View".
extension View {
    /// Masks `self` so its contents disappear in screenshots when enabled.
    /// When disabled, a plain `Rectangle()` acts as a full-opacity mask —
    /// a pass-through that changes nothing visually.
    func screenshotPreventingMask(_ isEnabled: Bool) -> some View {
        mask {
            // `Group` lets us return different view types from an `if/else`
            // branch without the compiler complaining about mismatched types.
            Group {
                if isEnabled {
                    ScreenshotPreventingMask()
                } else {
                    Rectangle() // opaque everywhere → nothing is masked out
                }
            }
            // Ensure the mask covers the entire screen — without this, the
            // status-bar / home-indicator areas leak through under a
            // `NavigationStack` or `TabView`.
            .ignoresSafeArea()
        }
    }
}

// MARK: - The UIKit bridge

//
// Why not just use SwiftUI's `SecureField`?
//
//     content.mask {
//         SecureField("", text: .constant("123123"))
//             .frame(maxWidth: .infinity, maxHeight: .infinity)
//             .contentShape(.rect)
//     }
//
// A `SecureField` sizes itself to its (tiny) text content, so it won't
// stretch to fill the masked area even with `.frame(maxWidth: .infinity)`.
// Dropping down to a `UITextField` via `UIViewRepresentable` gives us a
// view that honors the full available space, while still inheriting the
// system's screenshot-blanking behavior of `isSecureTextEntry`.
//
// Takeaway: `UIViewRepresentable` has two required methods —
//   • `makeUIView`   → create the UIKit view once
//   • `updateUIView` → sync SwiftUI state into it on every re-render
struct ScreenshotPreventingMask: UIViewRepresentable {
    func makeUIView(context _: Context) -> UIView {
        let view = UITextField()
        view.isSecureTextEntry = true // triggers the screenshot blanking
        view.text = ""
        view.isUserInteractionEnabled = false // it's a mask, not a real input

        // The "secure" rendering happens inside a private sublayer called
        // `UITextLayoutCanvasView`. We paint that sublayer opaque white so
        // the mask has solid coverage — otherwise the masked area would be
        // transparent and nothing would show through.
        if let autoHideLayer = findAutoHideLayer(view: view) {
            autoHideLayer.backgroundColor = UIColor.white.cgColor
        } else {
            // Fallback if Apple renames the class: the canvas layer is
            // empirically always the last sublayer.
            view.layer.sublayers?.last?.backgroundColor = UIColor.white.cgColor
        }
        return view
    }

    // Nothing to sync — the view is static once created.
    func updateUIView(_: UIView, context _: Context) {}

    /// Locates the private `UITextLayoutCanvasView`-backed sublayer by
    /// inspecting its delegate's debug description. This is a private-API
    /// sniff — brittle across iOS versions, hence the fallback above.
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
