//
//  PlayerItem.swift
//  animation
//

import SwiftUI

/// Player item model
let dummyDescription: String = "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book."

struct PlayerItem: Identifiable, Equatable {
    let id: UUID = .init()
    var title: String
    var author: String
    var image: String
    var description: String = dummyDescription
}

/// Sample data
var playItems: [PlayerItem] = [
    .init(title: "Mahito's Domain Expansion! | JUJUTSU KAISEN", author: "Crunchyroll", image: "IMG_1915"),
    .init(title: "Dune: Part Two | Official Trailer", author: "Warner Bros. Pictures", image: "IMG_1504"),
    .init(title: "Dune", author: "Vinal Pictures", image: "IMG_2104"),
    .init(title: "Dune Trailer (1984)", author: "Cardi B", image: "IMG_6162"),
    .init(title: "Frieren: Beyond Journey's End", author: "Crunchyroll", image: "IMG_8788")
]
