//
//  UICoordinator.swift
//  demoApp
// Model fro Apple photo app

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
    /// Scroll Positions
    var detailScrollPosition: String? // matches photoItem.id type
    
    func didDetailPageChanged() {
        if let updatedItem = items.first(where: { $0.id == detailScrollPosition }) {
            selectedItem = updatedItem
        }
    }
    
    func toggleView(show: Bool) {
        if show {
            detailScrollPosition = selectedItem?.id // trigger the detail scrollView to scroll to the selected photo item
            withAnimation(.easeInOut(duration: 2), completionCriteria: .removed) {
                animateView = true
            } completion: {
                self.showDetailView = true
            }
        } else {
            self.showDetailView = false
            withAnimation(.easeInOut(duration: 2), completionCriteria: .removed){
                animateView = false
            } completion: {
                self.resetAnimationProperties()
            }
        }
    }
    
    func resetAnimationProperties() {
        selectedItem = nil
        detailScrollPosition = nil
    }
}
