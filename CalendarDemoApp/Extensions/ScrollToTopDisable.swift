//
//  ScrollToTopDisable.swift
//  animation
//
//  Created on 1/24/26.

import SwiftUI

struct ScrollToTopDisable: UIViewRepresentable {
    func makeUIView(context _: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        DispatchQueue.main.async {
            if let scrollView = view.superview?.superview?.subviews.last?.subviews.first as? UIScrollView {
                scrollView.scrollsToTop = false
            }
        }
        return view
    }

    func updateUIView(_: UIView, context _: Context) {}
}
