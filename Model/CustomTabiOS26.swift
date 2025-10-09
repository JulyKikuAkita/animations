//
//  CustomTabiOS26.swift
//  animation
//
//  Created on 9/29/25.

import SwiftUI

enum CustomTabiOS26: String, CaseIterable {
    case home = "Home"
    case notificatinos = "Notifications"
    case settings = "Settings"

    var symbol: String {
        switch self {
        case .home:
            "house"
        case .notificatinos:
            "bell"
        case .settings:
            "gearshape"
        }
    }

    var actionSymbol: String {
        switch self {
        case .home:
            "plus"
        case .notificatinos:
            "tray.full.fill"
        case .settings:
            "cloud.moon.fill"
        }
    }

    var index: Int {
        Self.allCases.firstIndex(of: self) ?? 0
    }
}
