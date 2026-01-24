//
//  CustomHostingView.swift
//  animation
//
//  Created on 1/21/26.

import SwiftUI

/// Extracting main window to retrieve the window scene and create the overlay window for the dynamic island based toasts
@available(iOS 26.0, *)
class CustomHostingView: UIHostingController<ToastView> {
    var isStatusBarHidden: Bool = false

    override var prefersStatusBarHidden: Bool {
        isStatusBarHidden
    }
}
