//
//  View+Extensions.swift
//  animation
//
//  Created on 11/9/25.

import SwiftUI

public extension View {
    func noAnimation(_ contents: @escaping () -> Void) {
        var transaction = SwiftUI.Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            contents()
        }
    }
}
