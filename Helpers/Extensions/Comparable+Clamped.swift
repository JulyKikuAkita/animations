//
//  Comparable+Clamped.swift
//  animation
//

import Foundation

extension BinaryFloatingPoint {
    /// Clamps the value to a closed range.
    ///
    /// Usage:
    ///   let progress = (translation / height).clamped(to: 0...1)
    func clamped(to range: ClosedRange<Self>) -> Self {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
