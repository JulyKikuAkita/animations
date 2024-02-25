//
//  MAnchorKey.swift
//  animation
//
//  For reading the source and destination view bounds for our custom matched geometry effect

import SwiftUI

struct MAnchorKey: PreferenceKey {
    static func reduce(value: inout [String : Anchor<CGRect>],
                       nextValue: () -> [String : Anchor<CGRect>]) {
        value.merge(nextValue()) { $1 }
    }
    static var defaultValue: [String: Anchor<CGRect>] = [:]
}

