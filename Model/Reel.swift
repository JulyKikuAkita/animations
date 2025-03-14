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
    var description: String = "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book."
}

var reelsData: [Reel] = [
    .init(videoID: "Reel1", authorName: "Nanachi"),
    .init(videoID: "Reel2", authorName: "Banana"),
    .init(videoID: "Reel3", authorName: "Kiku"),
    .init(videoID: "Reel7", authorName: "Switerland"),
    .init(videoID: "Reel8", authorName: "Young puchi"),
    .init(videoID: "Reel9", authorName: "UPS driver"),
    .init(videoID: "Reel10", authorName: "Teamwork"),
    .init(videoID: "Reel11", authorName: "GoldenBoy"),
    .init(videoID: "Reel12", authorName: "Owlweee"),
//    .init(videoID: "Reel13", authorName: "jump into the sea"),
    .init(videoID: "Reel14", authorName: "coming"),
]

/// Like animation model
struct Like: Identifiable {
    var id: UUID = .init()
    var tappedRect: CGPoint = .zero
    var isAnimated: Bool = false
}
