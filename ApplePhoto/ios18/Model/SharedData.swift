//
//  SharedData.swift
//  demoApp

import SwiftUI

@Observable
class SharedData {
    /// photo page indicator below the photo scrollview
    var activePage: Int = 1
    /// expand photo grid scrollview
    var isExpanded: Bool = false
    /// MainScrollView properties
    var mainOffset: CGFloat = 0
    /// for drag position for the photo scroll view
    var canPullUp: Bool = false
    var canPullDown: Bool = false
    var progress: CGFloat = 0
}
