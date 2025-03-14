//
//  OffsetKey.swift
//  ThreadApp
import SwiftUI

struct OffsetKey: PreferenceKey {
    static var defaultValue: [String: Anchor<CGRect>] = [:]

    static func reduce(value: inout [String: Anchor<CGRect>],
                       nextValue: () -> [String: Anchor<CGRect>])
    {
        value.merge(nextValue()) { $1 }
    }
}
