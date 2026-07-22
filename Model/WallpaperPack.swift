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
          imageSets: ["IMG_0210", "IMG_0212", "IMG_0206", "owl", "sloth"]),
    .init(id: "Greece",
          description: dummyTitle,
          imageSets: ["IMG_0202", "IMG_0203", "IMG_0204", "owl", "sloth"]),
    .init(id: "Places",
          description: dummyTitle,
          imageSets: ["fox", "IMG_6162", "IMG_1504"]),
    .init(id: "Doge",
          description: dummyTitle,
          imageSets: ["IMG_1915", "nanachiPaint", "IMG_8788"]),
]
