//
//  Shape+Extensions.swift
//  animation
//
//  Created on 5/2/26.

import SwiftUI

extension Shape where Self == RoundedRectangle {
    static func rounded(cornerRadius: CGFloat = 20) -> RoundedRectangle {
        .rect(cornerRadius: cornerRadius, style: .continuous)
    }
}
