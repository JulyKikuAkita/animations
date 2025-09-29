//
//  PDFMaker.swift
//  PDFMaker
//
//  Created on 9/25/25.
//
// PDFRender generated content in an inverted view w/ maxium image quality
// if converting multiple pages, use FileMover instead

import PDFKit
import SwiftUI

enum PDFMaker {
    static func create(
        _ pageSize: PageSize = .a4(),
        pageCount: Int,
        fromat: UIGraphicsPDFRendererFormat = .default(),
        fileURL: URL = FileManager.default.temporaryDirectory.appending(path: "PDFMAKER_\(UUID().uuidString).pdf"),
        @ViewBuilder pageContent: (_ pageIndex: Int) -> some View
    ) throws -> URL? {
        let size = pageSize.size
        let rect = CGRect(origin: .zero, size: size)
        let renderer = UIGraphicsPDFRenderer(bounds: rect, format: fromat)
        try renderer.writePDF(to: fileURL) { context in
            /// drawing swiftUI views as each page
            for index in 0 ..< pageCount {
                let pageContent = pageContent(index)
                // Begin's each page
                context.beginPage()
                /// use ImageRenderer API to draw the image (that supports ImageRenderer)  to PDFRender without using UIHostingController
                let swiftUIRenderer = ImageRenderer(content: pageContent.frame(width: size.width, height: size.height))
                swiftUIRenderer.proposedSize = .init(size)

                /// Flipping inverted content
                context.cgContext.translateBy(x: 0, y: size.height)
                context.cgContext.scaleBy(x: 1, y: -1)

                swiftUIRenderer.render { _, swiftUIContext in
                    swiftUIContext(context.cgContext)
                }
            }
        }
        return fileURL
    }

    struct PageSize {
        let size: CGSize
        init(width: CGFloat, height: CGFloat) {
            size = .init(width: width, height: height)
        }

        static func a4() -> Self {
            .init(width: 595.2, height: 841.8)
        }

        static func usLetter() -> Self {
            .init(width: 612, height: 792)
        }
    }
}
