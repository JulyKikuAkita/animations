//
//  PDFRawView.swift
//  PDFMaker
//
//  Created on 9/25/25.

import SwiftUI

struct PDFRawView: View {
    @State private var pdfURL: URL?
    @State private var showFileMover: Bool = false

    var body: some View {
        NavigationStack {
            List {
                ShareLink("Shared PDF", item: fileURL!)

                Button("Export PDF") {
                    if let pdfURL = fileURL {
                        self.pdfURL = pdfURL
                        showFileMover.toggle()
                    }
                }
            }
            .navigationTitle(Text("PDF Helper"))
        }
        .fileMover(isPresented: $showFileMover, file: pdfURL) { _ in
        }
    }

    var fileURL: URL? {
        try? PDFMaker.create(
            pageCount: 3,
            pageContent: { pageIndex in
                Text("Hello World \(pageIndex)")
                    .font(.largeTitle.bold())
            }
        )
    }
}

#Preview {
    PDFRawView()
}
