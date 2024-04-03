//
//  Tab.swift
//  animation

import SwiftUI

enum Tab: String, CaseIterable {
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
}

/// Animated SF tab model
struct AnimatedTab: Identifiable {
    var id: UUID = .init()
    var tab: Tab
    var isAnimating: Bool?
}

enum VideoTab: String, CaseIterable {
    case home = "Home"
    case shorts = "Shorts"
    case subscription = "Subscription"
    case you = "You"
    case profile = "Profile"
    
    var symbol: String {
        switch self {
        case.home:
            return "house.fill"
        case .shorts:
            return "video.badge.waveform.fill"
        case .subscription:
            return "play.square.stack.fill"
        case .you:
            return "person.circle.fill"
        case .profile:
            return "person.2.crop.square.stack.fill"
        }
    }
}
