//
//  Tab.swift
//  animation

import SwiftUI

enum Tab_iOS17: String, CaseIterable {
    case photos = "photo.stack"
    case chat = "bubble.left.and.text.bubble.right"
    case apps = "square.3.layers.3d"
    case notifications = "bell.and.waves.left.and.right"
    case profile = "person.2.crop.square.stack.fill"
    
    var title: String {
        switch self {
        case.photos:
            return "Photos"
        case .chat:
            return "Chat"
        case .apps:
            return "Apps"
        case .notifications:
            return "Notifications"
        case .profile:
            return "Profile"
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
}

/// Animated SF tab model
struct AnimatedTab: Identifiable {
    var id: UUID = .init()
    var tab: Tab_iOS17
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
        case.home:
            return "house.fill"
        case .shorts:
            return "video.badge.waveform.fill"
        case .profile:
            return "play.square.stack.fill"
        case .carousel:
            return "person.circle.fill"
        case .progress:
            return "person.2.crop.square.stack.fill"
        }
    }
    
    var index: Int {
        return VideoTab.allCases.firstIndex(of: self) ?? 0
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
    .init(id: .privacy, idInt: 4, symbolImage: "gearshape.fill")
]
