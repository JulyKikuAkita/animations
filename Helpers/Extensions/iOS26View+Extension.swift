//
//  iOS26View+Extension.swift
//  animation
//
//  Created on 9/29/25.

import SwiftUI

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
