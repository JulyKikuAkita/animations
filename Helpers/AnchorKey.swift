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

struct OffsetKey: PreferenceKey {
    static func reduce(value: inout CGRect,
                       nextValue: () -> CGRect)
    {
        value = nextValue()
    }

    static var defaultValue: CGRect = .zero
}

struct CGFloatKey: PreferenceKey {
    static func reduce(value: inout CGFloat,
                       nextValue: () -> CGFloat)
    {
        value = nextValue()
    }

    static var defaultValue: CGFloat = .zero
}

struct SizeKey: PreferenceKey {
    static func reduce(value: inout CGSize,
                       nextValue: () -> CGSize)
    {
        value = nextValue()
    }

    static var defaultValue: CGSize = .zero
}
