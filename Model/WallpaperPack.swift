//
//  WallpaperPack.swift
//  animation
//
//  Created on 7/21/26.

import SwiftUI

struct WallpaperPack: Identifiable {
    var id: String
    var description: String
    var imageSets: [String]

    var title: String {
        id
    }
}

let packs: [WallpaperPack] = [
    .init(id: "Japan",
          description: dummyTitle,
          imageSets: ["IMG_0210", "IMG_0212", "IMG_0214"]),
    .init(id: "Greece",
          description: dummyTitle,
          imageSets: ["IMG_0202", "IMG_0203", "IMG_0204"]),
    .init(id: "Places",
          description: dummyTitle,
          imageSets: ["IMG_0205", "IMG_0207", "IMG_0213"]),
    .init(id: "Doge",
          description: dummyTitle,
          imageSets: ["IMG_1915", "nanachiPaint", "IMG_8788"]),
]
