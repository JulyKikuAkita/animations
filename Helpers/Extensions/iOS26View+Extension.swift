//
//  iOS26View+Extension.swift
//  animation
//
//  Created on 9/29/25.

import SwiftUI

// iOS 26 related helper
extension View {
    func blurFade(_ status: Bool) -> some View {
        blur(radius: status ? 0 : 5)
            .opacity(status ? 1 : 0)
    }

    func blurFadeViews(_ status: Bool) -> some View {
        compositingGroup()
            .blur(radius: status ? 0 : 10)
            .opacity(status ? 1 : 0)
    }
}

public extension View {
    var isiOS26OrLater: Bool {
        if #available(iOS 26, *) {
            true
        } else {
            false
        }
    }

    @ViewBuilder
    func tryGlassEffect() -> some View {
        if #available(iOS 26.0, tvOS 26.0, *) {
            self.glassEffect()
        } else {
            self
        }
    }

    @ViewBuilder
    func optionalGlassEffect(_ colorScheme: ColorScheme, cornerRadius: CGFloat = 30) -> some View {
        let backgroundColor = colorScheme == .dark ? Color.black : Color.white
        if #available(iOS 26.0, *) {
            self.glassEffect(
                .clear.tint(backgroundColor.opacity(0.75)).interactive(),
                in: .rect(cornerRadius: cornerRadius, style: .continuous)
            )
        } else {
            background {
                RoundedRectangle(
                    cornerRadius: cornerRadius,
                    style: .continuous
                )
                .fill(backgroundColor)
            }
        }
    }

    /// Shape-only
    @ViewBuilder
    func tryGlassEffect(in shape: some Shape) -> some View {
        if #available(iOS 26.0, tvOS 26.0, *) {
            self.glassEffect(in: shape)
        } else { self }
    }

    /// Disable any animation
    func noAnimation(_ content: @escaping () -> Void) {
        var transaction = Transaction()
        transaction.disablesAnimations = true

        withTransaction(transaction) {
            content()
        }
    }
}
