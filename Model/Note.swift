//
//  Note.swift
//  animation

import SwiftData
import SwiftUI

@Model
class Note {
    init(
        colorString: String,
        title: String,
        content: String
    ) {
        self.colorString = colorString
        self.title = title
        self.content = content
    }

    var id: String = UUID().uuidString
    var dateCreated: Date = Date()
    var colorString: String
    var title: String
    var content: String
    /// View Properties
    var allowsHitTesting: Bool = false

    /// Convert image asset to color
    var color: Color {
        if let image = UIImage(named: colorString) {
            return Color(image.averageColor() ?? .darkGray)
        }
        return .gray
    }
}
