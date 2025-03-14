//
//  ImageLinkModel.swift
//  animation
//
// find free image from: https://www.pexels.com/
// E.g,: https://www.pexels.com/photo/stunning-night-fireworks-over-city-skyline-29861388/
// convert it to image download api:
// https://images.pexels.com/photos/{photoid}/pexels-photo-{photoid}.jpeg?cs=srgb&fm=jpg&w=640&h=405
//
import SwiftUI

struct ImageLinkModel: Identifiable {
    var id: String = UUID().uuidString
    var altText: String
    var link: String
}

let PexelsImages: [ImageLinkModel] = [
    .init(altText: "Snow Fox Near Brown Rock",
          link: "https://images.pexels.com/photos/208976/pexels-photo-208976.jpeg?cs=srgb&fm=jpg&w=640&h=405"),
    .init(altText: "Stunning Night Fireworks Over City Skyline",
          link: "https://images.pexels.com/photos/10824704/pexels-photo-10824704.jpeg?cs=srgb&fm=jpg&w=640&h=360"),
    .init(altText: "Portrait of Fox",
          link: "https://images.pexels.com/photos/17047417/pexels-photo-17047417.jpeg?cs=srgb&fm=jpg&w=640&h=758"),
    .init(altText: "Tranquil Misty Mountains in Bavaria at Dawn",
          link: "https://images.pexels.com/photos/29825274/pexels-photo-29825274.jpeg?cs=srgb&fm=jpg&w=640&h=426"),
    .init(altText: "Northern lights on sky",
          link: "https://images.pexels.com/photos/18747835/pexels-photo-18747835.jpeg?cs=srgb&fm=jpg&w=640&h=426"),
    .init(altText: "Shiba Inu Resting on Pavement",
          link: "https://images.pexels.com/photos/2187304/pexels-photo-2187304.jpeg?cs=srgb&fm=jpg&w=640&h=427"),
    .init(altText: "White and Black Mountain",
          link: "https://images.pexels.com/photos/3090487/pexels-photo-3090487.jpeg?cs=srgb&fm=jpg&w=640&h=874"),
    .init(altText: "Traditional Chinese Architecture with Autumn Foliage",
          link: "https://images.pexels.com/photos/29381034/pexels-photo-29381034.jpeg?cs=srgb&fm=jpg&w=640&h=960"),
    .init(altText: "cottonbro",
          link: "https://images.pexels.com/photos/9669094/pexels-photo-9669094.jpeg?cs=srgb&dl=pexels-cottonbro-9669094.jpg&fm=jpg&w=640&h=960"),
]
