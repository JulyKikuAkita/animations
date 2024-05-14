//
//  ActionModel.swift
//  animation

import SwiftUI

struct Action: Identifiable {
    private(set) var id: UUID = .init()
    var tint: Color
    var icon: String
    var iconFont: Font = .title
    var iconTint: Color = .white
    var isEnabled: Bool = false
    var action: () -> ()
}
