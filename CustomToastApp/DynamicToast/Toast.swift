//
//  Toast.swift
//  animation
//
//  Created on 1/21/26.

import SwiftUI

struct Toast {
    private(set) var id: String = UUID().uuidString
    var symbol: String
    var symbolFont: Font
    var symbolForegroundStyle: (Color, Color)
    var title: String
    var message: String

    static var example1: Toast {
        Toast(
            symbol: "checkmark.seal.fill",
            symbolFont: .system(size: 35),
            symbolForegroundStyle: (.white, .green),
            title: "Transaction Success",
            message: "Your transaction with xxx is completed."
        )
    }

    static var example2: Toast {
        Toast(
            symbol: "xmark.seal.fill",
            symbolFont: .system(size: 35),
            symbolForegroundStyle: (.white, .red),
            title: "Transaction Failed",
            message: "Your transaction with xxx is failed."
        )
    }
}
