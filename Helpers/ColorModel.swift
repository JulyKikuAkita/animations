//
//  ColorModel.swift
//  animation

import SwiftData
import SwiftUI

@Model
class ColorModel {
    var name: String
    @Attribute(.transformable(by: ColorTransformer.self)) var color: UIColor

    init(name: String, color: Color) {
        self.name = name
        self.color = UIColor(color)
    }
}

/// Custom transformer to accept color values
class ColorTransformer: ValueTransformer {
    override func transformedValue(_ value: Any?) -> Any? {
        guard let color = value as? UIColor else { return nil }

        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: true)
            return data
        } catch {
            return nil
        }
    }

    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else { return nil }

        do {
            let color = try NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data)
            return color
        } catch {
            return nil
        }
    }

    override class func transformedValueClass() -> AnyClass {
        UIColor.self
    }

    override class func allowsReverseTransformation() -> Bool {
        true
    }

    static func register() {
        ValueTransformer.setValueTransformer(ColorTransformer(), forName: .init("ColorTransformer")) // the name need to be exactly match the class name
    }
}

enum DummyColors: String, CaseIterable {
    case red = "Red"
    case blue = "Blue"
    case green = "Green"
    case orange = "Orange"
    case purple = "Purple"
    case gray = "Gray"
    case accent = "AccentColor"
    case yellow = "Yellow"
    case brown = "Brown"
    case white = "White"
    case black = "Black"
    case pink = "Pink"
    case none = "None"

    var color: Color {
        switch self {
        case .red:
            .red
        case .blue:
            .blue
        case .green:
            .green
        case .orange:
            .orange
        case .purple:
            .purple
        case .gray:
            .gray
        case .yellow:
            .yellow
        case .brown:
            .brown
        case .white:
            .white
        case .black:
            .black
        case .accent:
            .accentColor
        case .none:
            .clear
        case .pink:
            .pink
        }
    }
}
