//
//  PhotoModel.swift
//  animation
//
//  Created on 1/24/26.
import SwiftUI

/// Reel model and sample video files
struct Photo: Identifiable {
    var id: UUID = .init()
    var assetName: String
    var author: String
    var imageID: String {
        "IMG:\(id.uuidString)"
    }
}

let scenic: [Photo] = [
    .init(assetName: "IMG_0201", author: "Kenting"),
    .init(assetName: "IMG_0202", author: "Naxos"),
    .init(assetName: "IMG_0203", author: "Santorini"),
    .init(assetName: "IMG_0205", author: "Hallstatt"),
]

let illustrations: [Photo] = [
    .init(assetName: "fox", author: "Fox"),
    .init(assetName: "owl", author: "Banana"),
    .init(assetName: "sloth", author: "Nanachi"),
    .init(assetName: "fox_color", author: "Akita"),
]
