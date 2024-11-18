//
//  HeroConfig.swift
//  Profiles

import SwiftUI

struct HeroConfiguration {
    var layer: String? /// the profile image type, string, UIImage, image etc
    var coordinates: (CGRect, CGRect) = (.zero, .zero)
    var isExpandedCompletely: Bool = false
    var activeId: String = ""
}
