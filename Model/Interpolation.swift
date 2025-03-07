//
//  Interpolation.swift
//  animation
//
// iOS 17 horizontal scrollable view
// input of progress 0.5 -> map to 10
// input of [0, 0.5, 1] -> output: [0, 10, 15]
//
import SwiftUI

extension CGFloat {
    func interpolate(inputRange: [CGFloat], outputRange: [CGFloat]) -> CGFloat {
        /// inputRange.count and outputRange.count needs to be the same to work
        guard inputRange.count == outputRange.count else {
            return inputRange[0] // any value
        }
        /// If value less than it's initial input range
        let x = self
        let length = inputRange.count - 1
        if x <= inputRange[0] { return outputRange[0] }

        for index in 1...length {
            let x1 = inputRange[index - 1]
            let x2 = inputRange[index]

            let y1 = outputRange[index - 1]
            let y2 = outputRange[index]

            /// Linear interpolation formula: y1 + ((y2 - y1) / (x2 - x1)) * (x - x1)
            if x <= inputRange[index] {
                let y = y1 + ((y2 - y1) / (x2 - x1)) * (x - x1)
                return y
            }
        }

        /// If value exceeds it's maximum input range
        return outputRange[length]
    }
}
