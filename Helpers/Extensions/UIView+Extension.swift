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

    /// Extracting all subview with the given type
    func subViews<T: UIView>(type: T.Type) -> [T] {
        subviews.compactMap { $0 as? T } +
            subviews.flatMap { $0.subViews(type: type) }
    }
}
