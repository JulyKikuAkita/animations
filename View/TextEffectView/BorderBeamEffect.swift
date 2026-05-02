//
//  BorderBeamEffect.swift
//  animation
//
//  Created on 5/2/26.

import SwiftUI

extension View {
    @ViewBuilder
    func borderBeam(
        border: Color,
        beam: [Color],
        beamBlur: CGFloat,
        cornerRadius: CGFloat,
        isEnable: Bool = true
    ) -> some View {
        modifier(
            BorderBeamEffect(
                border: border,
                beam: beam,
                beamBlur: beamBlur,
                cornerRadius: cornerRadius,
                isEnable: isEnable
            )
        )
    }
}

struct BorderBeamEffect: ViewModifier {
    var border: Color
    var beam: [Color]
    var beamBlur: CGFloat
    var cornerRadius: CGFloat
    var isEnable: Bool
    func body(content: Content) -> some View {
        content
    }
}
