//
//  Animation+Extension.swift
//  animation
//

import SwiftUI

public extension Animation {
    static func iSpring(
        duration: TimeInterval = 0.3,
        bounce: Double = 0,
        initialVelocity: Double = 0
    ) -> Animation {
        .interpolatingSpring(
            duration: duration,
            bounce: bounce,
            initialVelocity: initialVelocity
        )
    }
}
