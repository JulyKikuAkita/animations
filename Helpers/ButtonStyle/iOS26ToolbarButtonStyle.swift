//
//  iOS26ToolbarButtonStyle.swift
//  animation
//
//  Created on 12/15/25.

import SwiftUI

struct ToolbarButtonStyleiOS26: ButtonStyle {
    var isTinted: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        if #available(iOS 26.0, *) {
            configuration.label
                .frame(width: isTinted ? nil : 48, height: isTinted ? 36 : 48)
                .padding(.horizontal, isTinted ? 15 : 0)
                .contentShape(.rect)
                .glassEffect(.regular.tint(.blue.opacity(isTinted ? 1 : 0)).interactive(), in: .capsule)

        } else {
            configuration.label
                .foregroundStyle(.blue)
                .frame(height: isTinted ? 30 : nil)
                .padding(.horizontal, isTinted ? 15 : 0)
                .contentShape(.rect)
                .background(.blue.opacity(isTinted ? 1 : 0), in: .capsule)
        }
    }
}
