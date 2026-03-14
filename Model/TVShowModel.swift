//
//  TVShowModel.swift
//  animation

import SwiftUI

struct TVShow: Identifiable {
    let id: String = UUID().uuidString
    let title: String
    let subtitle: String
    let content: String
    let artwork: String
}

let tvShows: [TVShow] = [
    .init(title: "MONARCH", subtitle: "LEGACY OF MONSTERS", content: "TV Show * Adventure * Sci-Fi", artwork: "fox"),
    .init(title: "DARK", subtitle: "MATTER", content: "TV Show * Sci-Fi * Thriller", artwork: "IMG_0202"),
    .init(title: "FOR ALL", subtitle: "TO BE WILD", content: "TV Show * Drama * Sci-Fi", artwork: "AI_grn"),
    .init(title: "TINY", subtitle: "WORLD", content: "TV Show * Documentary", artwork: "q&a"),
    .init(title: "TINY", subtitle: "WORLD", content: "TV Show * Documentary", artwork: "nanachiPaint"),
]
