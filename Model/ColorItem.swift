//
//  ColorItem.swift
//  animation

import SwiftUI

struct ColorItem: Identifiable {
    var id: UUID = .init()
    var color: Color
    /// Items location on screen
    var location: CGRect = .zero
}

let colors: [Color] = [.red, .blue, .purple, .yellow, .black, .indigo, .cyan, .brown, .mint, .orange]
