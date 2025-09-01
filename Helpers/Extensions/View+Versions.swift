//
//  View+Versions.swift
//  animation
//
import SwiftUI

public extension View {
    var isiOS26OrLater: Bool {
        if #available(iOS 26, *) {
            true
        } else {
            false
        }
    }
}
