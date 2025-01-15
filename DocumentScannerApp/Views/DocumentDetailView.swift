//
//  DocumentDetailView.swift
//  DocumentScannerApp

import SwiftUI

struct DocumentDetailView: View {
    var document: Document
    var body: some View {
        if let pages = document.pages?.sorted(by: { $0.pageIndex < $1.pageIndex }) {
            VStack(spacing: 10) {
                // header view
                TabView {
                    ForEach(pages) { page in
                        if let image = UIImage(data: page.pageData) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        }
                    }
                }
                .tabViewStyle(.automatic)
                
                /// footer view
            }
            .background(.black)
            .toolbarVisibility(.hidden, for: .navigationBar)
        }
    }
}
