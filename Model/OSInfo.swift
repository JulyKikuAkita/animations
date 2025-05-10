//
//  OSInfo.swift
//  animation

enum OSInfo: String, CaseIterable {
    case iOS
    case appleWatch = "watchOS"
    case ipad = "iPadOS"
    case macbook = "macOS"
    case visionOS

    var symbolImage: String {
        switch self {
        case .iOS: "iphone"
        case .appleWatch: "applewatch"
        case .ipad: "ipad"
        case .macbook: "macbook"
        case .visionOS: "vision.pro"
        }
    }
}
