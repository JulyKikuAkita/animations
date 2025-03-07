//
//  PS_Tab.swift
//  PlayStationApp
//

import SwiftUI

enum PS_Tab: String, CaseIterable {
    case play = "Play"
    case explore = "Explore"
    case store = "PS Store"
    case library = "Game Library"
    case search = "Search"

    var index: CGFloat {
        return CGFloat(PS_Tab.allCases.firstIndex(of: self) ?? 0)
    }

    static var count: CGFloat {
        return CGFloat(PS_Tab.allCases.count)
    }
}
