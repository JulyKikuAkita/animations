//
//  PicItem.swift
//  ThreadApp

import SwiftUI

// Model

struct PicItem: Identifiable {
    let id: UUID = .init()
    var image: String
}
/// Constructing pic using asset images
private var pics: [PicItem] = (1...5).compactMap{ index -> PicItem? in
    return .init(image: "IMG_020\(index)")
}

private var pics1: [PicItem] = (1...5).reversed().compactMap{ index -> PicItem? in
    return .init(image: "IMG_020\(index)")
}

struct Post: Identifiable{
    let id: UUID = .init()
    var username: String
    var content: String
    var pics: [PicItem]
    /// View based properties
    var scrollPosition: UUID?
}

/// Sample Posts
var samplePosts: [Post] = [
    .init(username: "Nanachi", content: "Natural Pics", pics: pics),
    .init(username: "Nanachi", content: "Natural Pics", pics: pics1)
]
