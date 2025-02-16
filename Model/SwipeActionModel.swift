//
//  SwipeActionModel.swift
//  animation
import SwiftUI

/// Swipe Action Model
struct SwipeActionModel: Identifiable {
    var id = UUID().uuidString
    var symbolImage: String
    var tint: Color
    var background: Color
    /// Properties
    var font: Font = .title3
    var size: CGSize = .init(width: 45, height: 45)
    var shape: some Shape = .circle
    var action: (inout Bool) -> ()
}
