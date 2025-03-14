//
//  Tag.swift
//  animation

import SwiftUI

struct Tag: Identifiable, Hashable {
    var id: UUID = .init()
    var value: String
    var isInitial: Bool = false
}
