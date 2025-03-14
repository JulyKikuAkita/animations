//
//  CGSize+Extension.swift
//  DocumentScannerApp

import SwiftUI

/// return a new size based on the given aspect ratio
extension CGSize {
    func aspectFit(_ to: CGSize) -> CGSize {
        let scaleX = to.width / width
        let scaleY = to.height / height

        let aspectRatio = min(scaleX, scaleY)
        return .init(width: aspectRatio * width, height: aspectRatio * height)
    }
}
