//
//  Comparable+Clamped.swift
//  animation
//

import Foundation
import SwiftUI

public extension CGFloat {
    /// Constrains the value to a closed range.
    ///
    /// Usage:
    ///   let progress = (translation / height).constrained(to: 0...1)
    func constrained(to range: ClosedRange<Self>) -> Self {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
