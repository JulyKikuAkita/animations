//
//  UIView+Extension.swift
//  animation
//
//  Created on 10/27/25.

import UIKit

extension UIView {
    func allSubViews() -> [UIView] {
        var result: [UIView] = subviews.compactMap(\.self)
        for subview in subviews {
            result.append(contentsOf: subview.allSubViews())
        }
        return result
    }
}
