//
//  PassThroughWindow.swift
//  animation
//
//  Created on 1/21/26.

import SwiftUI

/// Custom UIWindow that passes through touches in transparent / non-interactive areas
@Observable // without this, SwiftUI will not update when isPresented changes
class PassThroughWindow: UIWindow {
    /// View based properties
    var toast: Toast? = nil
    var isPresented: Bool = false

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let hitView = super.hitTest(point, with: event),
              let rootView = rootViewController?.view
        else {
            return nil
        }

        if #available(iOS 26, *) {
            if rootView.layer.hitTest(point)?.name == nil {
                return rootView
            }
            return nil
        } else {
            if #unavailable(iOS 18) {
                /// before iOS 18
                return hitView == rootView ? nil : hitView
            } else {
                /// [iOS 18 , iOS 26]
                for subview in rootView.subviews.reversed() {
                    let pointInSubView = subview.convert(point, from: rootView)
                    if subview.hitTest(pointInSubView, with: event) != nil {
                        return hitView
                    }
                }
                return nil
            }
        }
    }
}
