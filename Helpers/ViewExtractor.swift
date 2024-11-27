//
//  ViewExtractor.swift
//  animation

import SwiftUI

// extract swiftUI view from UIKit view or vice versa
// Add this to the view we want to tract (not after the modifier otherwise we get result as modifier)
extension View {
    @ViewBuilder
    func ViewExtractor(result: @escaping (UIView) -> ()) -> some View {
        self
            .background(ViewExtractHelper(result: result))
            .compositingGroup()
    }
}

// the view was compose of 2 super views and swiftUI view is at the top of the group, it's the last subview property
// each swiftUI view serves as a wrapper around a UIKit view and the initial view will be a wrapper and within it the associated UIKit View
fileprivate struct ViewExtractHelper: UIViewRepresentable {
    var result: (UIView) -> ()
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        DispatchQueue.main.async {
            if let superview = view.superview?.superview?.subviews.last?.subviews.first {
                result(superview)
            }
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
    }
}
