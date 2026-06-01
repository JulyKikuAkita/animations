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

enum MailTab: String, MailTabItem {
    case primary = "Primary"
    case transactions = "Transactions"
    case updates = "Updates"
    case promotions = "Promotions"
    case allMails = "All Mail"

    var title: String {
        rawValue
    }

    var symbol: String {
        switch self {
        case .primary: "person.fill"
        case .transactions: "cart.fill"
        case .updates: "text.bubble.fill"
        case .promotions: "megaphone.fill"
        case .allMails: "tray.fill"
        }
    }

    var activeBackground: Color {
        switch self {
        case .primary: Color.blue
        case .transactions: Color.green
        case .updates: Color.indigo
        case .promotions: Color.pink
        case .allMails: Color.white
        }
    }

    var activeTint: Color {
        switch self {
        case .primary, .transactions, .updates, .promotions: Color.white
        case .allMails: Color.black
        }
    }
}

protocol MailTabItem: CaseIterable, Equatable, Hashable {
    var symbol: String { get }
    var title: String { get }
    var activeTint: Color { get }
    var activeBackground: Color { get }
}
