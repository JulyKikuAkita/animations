//
//  View+Extensions.swift
//  Habit
//
import SwiftUI

extension View {
    @ViewBuilder
    func hSpacing(_ alignment: Alignment) -> some View {
        frame(maxWidth: .infinity, alignment: alignment)
    }

    @ViewBuilder
    func vSpacing(_ alignment: Alignment) -> some View {
        frame(maxHeight: .infinity, alignment: alignment)
    }

    @ViewBuilder
    func applyPaddedBackground(_ radius: CGFloat, hPadding: CGFloat = 15, vPadding: CGFloat = 15) -> some View {
        padding(.horizontal, hPadding)
            .padding(.vertical, vPadding)
            .background(.background, in: .rect(cornerRadius: radius))
    }

    @ViewBuilder
    func disableWithOpacity(_ status: Bool) -> some View {
        disabled(status)
            .opacity(status ? 0.5 : 1)
    }

    @ViewBuilder
    func opacityShadow(_ color: Color, opacity: CGFloat, radius: CGFloat) -> some View {
        shadow(color: color.opacity(opacity), radius: radius)
    }
}
