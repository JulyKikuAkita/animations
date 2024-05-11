//
//  UICoordinator.swift
//  demoApp


import SwiftUI

@Observable
class UICoordinator {
    var items: [PhotoItem] = sampleItems.compactMap({
        PhotoItem(title: $0.title, image: $0.image, previewImage: $0.image)
    })
    
    /// Animation properties
    var selectedItem: PhotoItem?
    var animateView: Bool = false
    var showDetailView: Bool = false
}
