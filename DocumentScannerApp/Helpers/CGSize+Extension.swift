//
//  CGSize+Extension.swift
//  DocumentScannerApp

import SwiftUI

/// return a new size based on the given aspect ratio
extension CGSize {
    func aspectFit(_ to: CGSize) -> CGSize {
        let scaleX = to.width / self.width
        let scaleY = to.height / self.height

        let aspectRatio = min(scaleX, scaleY)
        return .init(width: aspectRatio * width, height: aspectRatio * height)
    }
 }
