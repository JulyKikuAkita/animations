//
//  Document.swift
//  DocumentScannerApp

import SwiftData
import SwiftUI

@Model
class Document {
    var name: String
    var createdAt: Date = Date()
    /// cascade rule ensure all associated pages are deleted when the document is deleted
    @Relationship(deleteRule: .cascade, inverse: \DocumentPage.document)
    var pages: [DocumentPage]?
    var isLocked: Bool = false

    /// for zoom transition animation
    var uniqueViewID: String = UUID().uuidString

    init(name: String, pages: [DocumentPage]? = nil) {
        self.name = name
        self.pages = pages
    }
}
