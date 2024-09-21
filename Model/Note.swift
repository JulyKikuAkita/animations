//
//  Note.swift
//  animation

import SwiftUI

struct Note: Identifiable {
    var id: String = UUID().uuidString
    var color: Color
}

var mockNotes: [Note] = [
    .init(color: .orange),
    .init(color: .brown),
    .init(color: .green),
    .init(color: .purple),
    .init(color: .gray),
]
