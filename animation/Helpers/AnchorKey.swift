//
//  AnchorKey.swift
//  animation
//
//  AnchorKey is to store source and destination frame values
//  to achieve a smooth progress-based transition animation

import SwiftUI

struct AnchorKey: PreferenceKey {
    static func reduce(value: inout [String: Anchor<CGRect>],
                       nextValue: () -> [String: Anchor<CGRect>])
    {
        value.merge(nextValue()) { $1 }
    }

    static var defaultValue: [String: Anchor<CGRect>] = [:]
}
