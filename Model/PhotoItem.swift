//
//  photoItem.swift
//  demoApp

import SwiftUI

struct PhotoItem: Identifiable, Hashable {
    var id: String = UUID().uuidString
    var title: String
    var image: UIImage?
    var previewImage: UIImage?
    var appeared: Bool = false
}

var sampleItems: [PhotoItem] = [
    .init(title: "Kenting", image: UIImage(named: "IMG_0201")),
    .init(title: "Naxos", image: UIImage(named: "IMG_0202")),
    .init(title: "Santorini", image: UIImage(named: "IMG_0203")),
    .init(title: "Naxos", image: UIImage(named: "IMG_0204")),
    .init(title: "Hallstatt", image: UIImage(named: "IMG_0205")),
    .init(title: "Kyoto", image: UIImage(named: "IMG_0206")),
    .init(title: "Budapest", image: UIImage(named: "IMG_0207")),
    .init(title: "Lugano", image: UIImage(named: "IMG_0208")),
    .init(title: "San Francisco", image: UIImage(named: "IMG_0209")),
    .init(title: "Kyoto", image: UIImage(named: "IMG_0210")),
    .init(title: "Tokyo", image: UIImage(named: "IMG_0211")),
    .init(title: "Kawaguchi", image: UIImage(named: "IMG_0212")),
    .init(title: "Dublin", image: UIImage(named: "IMG_0213")),
    .init(title: "Gifu", image: UIImage(named: "IMG_0214")),
    .init(title: "Santorini", image: UIImage(named: "IMG_0215")),
    .init(title: "Kiku", image: UIImage(named: "IMG_1504")),
    .init(title: "Hachi", image: UIImage(named: "IMG_1915")),
    .init(title: "Akita", image: UIImage(named: "IMG_2104")),
    .init(title: "Nanachi", image: UIImage(named: "IMG_6162")),
    .init(title: "Banana", image: UIImage(named: "IMG_8788")),
    .init(title: "Fox", image: UIImage(named: "fox")),
]
