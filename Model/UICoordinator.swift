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
    var detailIndicatorPosition: String? 
    /// Gesture Properties
    var offset: CGSize = .zero
    var dragProgress: CGFloat = 0
    
    func didDetailPageChanged() {
        if let updatedItem = items.first(where: { $0.id == detailScrollPosition }) {
            selectedItem = updatedItem
            /// Updating indicator position
            withAnimation(.easeInOut(duration: 0.1)) {
                detailIndicatorPosition = updatedItem.id
            }
        }
    }
    
    func didDetailIndicatorChanged() {
        if let updatedItem = items.first(where: { $0.id == detailIndicatorPosition }) {
            selectedItem = updatedItem
            /// Updating Detail paging view as well
            detailScrollPosition = updatedItem.id
        }
    }
    
    func toggleView(show: Bool) {
        if show {
            detailScrollPosition = selectedItem?.id // trigger the detail scrollView to scroll to the selected photo item
            detailIndicatorPosition = selectedItem?.id // ensure bottom carousel starts with the selected item
            withAnimation(.easeInOut(duration: 0.2), completionCriteria: .removed) {
                animateView = true
            } completion: {
                self.showDetailView = true
            }
        } else {
            self.showDetailView = false
            withAnimation(.easeInOut(duration: 0.2), completionCriteria: .removed){
                animateView = false
                offset = .zero
            } completion: {
                self.resetAnimationProperties()
            }
        }
    }
    
    func resetAnimationProperties() {
        selectedItem = nil
        detailScrollPosition = nil
        offset = .zero
        dragProgress = 0
        detailIndicatorPosition = nil
    }
}
