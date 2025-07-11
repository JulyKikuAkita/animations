//
//  Tab_iOS17.swift
//  animation

import SwiftUI

enum TabiOS17: String, CaseIterable {
    case photos = "photo.stack"
    case chat = "bubble.left.and.text.bubble.right"
    case apps = "square.3.layers.3d"
    case notifications = "bell.and.waves.left.and.right"
    case profile = "person.2.crop.square.stack.fill"

    var title: String {
        switch self {
        case .photos:
            "Photos"
        case .chat:
            "Chat"
        case .apps:
            "Apps"
        case .notifications:
            "Notifications"
        case .profile:
            "Profile"
        }
    }

    /// for  SwiftUI TabView Offset Reader - Scrollable Tabs
    var color: Color {
        switch self {
        case .apps:
            .purple
        case .photos:
            .pink
        case .chat:
            .orange
        case .notifications:
            .green
        case .profile:
            .cyan
        }
    }

    /// DraggableTabbariOS18DemoView
    var index: Int {
        Self.allCases.firstIndex(of: self) ?? 0
    }
}

/// Animated SF tab model
struct AnimatedTab: Identifiable {
    var id: UUID = .init()
    var tab: TabiOS17
    var isAnimating: Bool?
}

enum VideoTab: String, CaseIterable {
    case home = "Home"
    case shorts = "Shorts"
    case progress = "Progress"
    case carousel = "Carousel"
    case profile = "Profile"

    var symbol: String {
        switch self {
        case .home:
            "house.fill"
        case .shorts:
            "video.badge.waveform.fill"
        case .profile:
            "play.square.stack.fill"
        case .carousel:
            "person.circle.fill"
        case .progress:
            "person.2.crop.square.stack.fill"
        }
    }

    var index: Int {
        VideoTab.allCases.firstIndex(of: self) ?? 0
    }
}

enum AppleMusicTab: String, CaseIterable {
    /// rawValue: system image name
    case listenNow = "play.circle.fill"
    case browse = "square.grid.2x2.fill"
    case radis = "dot.radiowaves.left.and.right"
    case music = "play.square.stack"
    case search = "magnifyingglass"

    var title: String {
        switch self {
        case .listenNow:
            "Listen Now"
        case .browse:
            "Browse"
        case .radis:
            "Radis"
        case .music:
            "Music"
        case .search:
            "Search"
        }
    }
}

enum AppleFindMyTab: String, CaseIterable {
    case people = "People"
    case devices = "Devices"
    case items = "Items"
    case me = "Me"

    var symbolImage: String {
        switch self {
        case .people:
            "person.2"
        case .devices:
            "macbook.and.iphone"
        case .items:
            "circle.grid.2x2.fill"
        case .me:
            "location.slash"
        }
    }
}

enum SimpleTabs: String, CaseIterable {
    case all = "All"
    case game = "Games"
    case music = "Music"
    case food = "Food"
}

/// horizontal scrollable tabs
struct TabModel: Identifiable {
    private(set) var id: HorizonTab
    var size: CGSize = .zero
    var minX: CGFloat = .zero

    var idInt: Int = 0
    var symbolImage: String = ""
    var rect: CGRect = .zero

    enum HorizonTab: String, CaseIterable {
        case research = "Research"
        case development = "Development"
        case analytics = "Analytics"
        case audience = "Audience"
        case privacy = "Privacy"
    }
}

let defaultOrderTabs: [TabModel] = [
    .init(id: .analytics, idInt: 0, symbolImage: "house.fill"),
    .init(id: .research, idInt: 1, symbolImage: "magnifyingglass"),
    .init(id: .audience, idInt: 2, symbolImage: "bell.fill"),
    .init(id: .development, idInt: 3, symbolImage: "person.2.fill"),
    .init(id: .privacy, idInt: 4, symbolImage: "gearshape.fill"),
]
