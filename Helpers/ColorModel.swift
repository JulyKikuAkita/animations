//
//  ColorModel.swift
//  animation

import SwiftUI
import SwiftData

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
        return UIColor.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    // wip: https://www.youtube.com/watch?v=VJbsc1lS4mQ&list=PLimqJDzPI-H97JcePxWNwBXJoGS-Ro3a-&index=101
    // 4:13
}

enum DummyColors: String, CaseIterable {
    case red = "RED"
    case blue = "Blue"
    case green = "Green"
}
