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
    var photoScrollOffset: CGFloat = 0
    var selectedCategory:String = "Years"
    
    /// for drag position for the photo scroll view: evaluating whether the scrollView can be pull up/down for expanding/minimized view
    var canPullUp: Bool = false
    var canPullDown: Bool = false
    var progress: CGFloat = 0
}
