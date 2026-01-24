//
//  WindowExtractor.swift
//  animation
//
//  Created on 1/21/26.

import SwiftUI

/// Extracting main window to retrieve the window scene and create the overlay window to display dynamic island toasts
struct WindowExtractor: UIViewRepresentable {
    var result: (UIWindow) -> Void
    func makeUIView(context _: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        DispatchQueue.main.async {
            if let window = view.window {
                result(window)
            }
        }
        return view
    }

    func updateUIView(_: some UIView, context _: Context) {}
}
