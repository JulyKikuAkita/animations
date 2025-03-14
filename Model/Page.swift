//
//  Page.swift
//  animation

import SwiftUI

enum Page: String, CaseIterable {
    case page1 = "playstation.logo"
    case page2 = "gamecontroller.fill"
    case page3 = "xbox.logo"
    case page4 = "arcade.stick.console.fill"

    var title: String {
        switch self {
        case .page1: "Welcome to PlayStation"
        case .page2: "DualSense wireless controller"
        case .page3: "Welcome to Xbox"
        case .page4: "Welcome to Apple Arcade"
        }
    }

    var subTitle: String {
        switch self {
        case .page1: "Your journey starts here"
        case .page2: "Discover a deeper gaming experience\nwith the DualSense controller"
        case .page3: "Stream your PS5 to Apple devices"
        case .page4: "Apple Arcade gives you unlimited, uninterrupted access to the games you love"
        }
    }

    var index: CGFloat {
        switch self {
        case .page1: 0
        case .page2: 1
        case .page3: 2
        case .page4: 3
        }
    }

    // fetch the next page if it's not the last page
    var nextPage: Page {
        let index = Int(index) + 1
        if index < Page.allCases.count {
            return Page.allCases[index]
        }
        return self
    }

    // fetch the previous page if it's not the first page
    var previousPage: Page {
        let index = Int(index) - 1
        if index >= 0 {
            return Page.allCases[index]
        }
        return self
    }
}
