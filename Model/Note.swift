//
//  Note.swift
//  animation

import SwiftUI

struct Note: Identifiable {
    var id: String = UUID().uuidString
    var color: Color
    var allowsHitTesting: Bool = false // when tapped, then allow hit testing
}

var mockNotes: [Note] = [
    .init(color: .orange),
    .init(color: .brown),
    .init(color: .green),
    .init(color: .purple),
    .init(color: .gray),
]
