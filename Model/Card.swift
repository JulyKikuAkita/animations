//
//  Card.swift
//  animation

import SwiftUI

struct Card: Identifiable, Hashable, Equatable {
    var id: UUID = .init()
    var image: String
    var previousOffset: CGFloat = 0
    var title: String
    var subTitle: String
}

var firstSetCards = [
    Card(image: "IMG_0201", title: "Kenting", subTitle: "Taiwan"),
    Card(image: "IMG_0202", title: "Naxos", subTitle: "Greece"),
    Card(image: "IMG_0203", title: "Santorini", subTitle: "Greece"),
    Card(image: "IMG_0204", title: "Naxos", subTitle: "Greece"),
    Card(image: "IMG_0205", title: "Hallstatt", subTitle: "Austria"),
    Card(image: "IMG_0206", title: "Kyoto", subTitle: "Japan"),
    Card(image: "IMG_0207", title: "Budapest", subTitle: "Hungary"),
    Card(image: "IMG_0208", title: "Lugano", subTitle: "Switerland"),
]

var secondSetCards = [
    Card(image: "IMG_0208", title: "Lugano", subTitle: "Switerland"),
    Card(image: "IMG_0209", title: "San Francisco", subTitle: "U.S.A."),
    Card(image: "IMG_0210", title: "Kyoto", subTitle: "Japan"),
    Card(image: "IMG_0211", title: "Tokyo", subTitle: "Japan"),
    Card(image: "IMG_0212", title: "Kawaguchi", subTitle: "Japan"),
    Card(image: "IMG_0213", title: "Dublin", subTitle: "Ireland"),
    Card(image: "IMG_0214", title: "Gifu", subTitle: "Japan"),
    Card(image: "IMG_0215", title: "Santorini", subTitle: "Greece"),
]
