//
//  Reel.swift
//  animation
import SwiftUI

/// Reel model and sample video files
struct Reel: Identifiable {
    var id: UUID = .init()
    var videoID: String
    var authorName: String
    var isLiked: Bool = false
}

var reelsData: [Reel] = [
    .init(videoID: "Reel1", authorName: "Nanachi"),
    .init(videoID: "Reel2", authorName: "Banana"),
    .init(videoID: "Reel3", authorName: "Kiku"),
    .init(videoID: "Reel4", authorName: "Unknown"),
    .init(videoID: "Reel5", authorName: "Real Real"),
]

/// Like animation model
struct Like: Identifiable {
    var id: UUID = .init()
    var tappedRect: CGPoint = .zero
    var isAnimated: Bool = false
}
