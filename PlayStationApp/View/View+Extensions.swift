//
//  View+Extensions.swift
//  PlayStationApp

import SwiftUI

extension View {
    var safeArea: UIEdgeInsets {
        if let safeArea = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.safeAreaInsets {
            return safeArea
        }
        return .zero
    }
}

/// Glow custom view extension
extension View {
    func glow(_ color: Color, radius: CGFloat) -> some View {
        shadow(color: color, radius: radius / 2.5)
            .shadow(color: color, radius: radius / 2.5)
            .shadow(color: color, radius: radius / 2.5)
    }
}
