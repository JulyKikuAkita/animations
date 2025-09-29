//
//  PDFStatementView.swift
//  PDFMaker
//
//  Created on 9/25/25.

import SwiftUI

struct Transaction: Identifiable {
    var id: String = UUID().uuidString
    var name: String = "Labubu"
    var account: String = "123456789"
    var date: String = "2025-09-25"
    var category: String = "Toy"
    var amount: String = "87.87"
}

let mockTransactions: [Transaction] = (1 ... 50).compactMap { _ in .init() }

struct ExportablePageView: View {
    var pageIndex: Int
    var transaction: [Transaction]
    var body: some View {
        VStack(spacing: 0) {
            /// Custom header view
            headerView()

            /// Transaction view
            ForEach(mockTransactions) { transaction in
                transationRowView(transaction)
            }
        }
        .padding(15)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .overlay(alignment: .bottom) {
            Text("\(pageIndex + 1)")
                .font(.caption2)
                .fontWeight(.semibold)
                .offset(y: -8)
        }
        .background(.white)
        .environment(\.colorScheme, .light)
    }

    func headerView() -> some View {
        HStack(spacing: 10) {
            Image(systemName: "applelogo")
                .font(.largeTitle)
                .foregroundStyle(.white)
                .frame(width: 50, height: 50)
                .background(.black, in: .rect(cornerRadius: 15))

            VStack(alignment: .leading, spacing: 4) {
                Text("App - Item Description")
                    .font(.callout)
                Text("Nanachi Ltd.")
                    .font(.caption)
            }
            .lineLimit(1)

            Spacer(minLength: 0)
        }
        .frame(height: 50)
        .frame(height: 80, alignment: .top)
    }

    func transationRowView(_ transaction: Transaction) -> some View {
        VStack(spacing: 4) {
            HStack(alignment: .center, spacing: 6) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(transaction.name)
                        .font(.callout)
                        .lineLimit(1)

                    Text(transaction.amount)
                        .font(.caption)
                        .fontWeight(.medium)
                        .underline()
                        .lineLimit(1)

                    Text("Category: " + "\(transaction.category)")
                        .font(.caption2)
                        .lineLimit(1)
                        .foregroundStyle(.gray)
                }

                Spacer(minLength: 0)

                VStack(alignment: .center, spacing: 6) {
                    Text(transaction.amount)
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundStyle(.green)

                    Text(transaction.date)
                        .font(.caption2)
                        .foregroundStyle(.gray)
                }
            }

            Divider()
        }
        .frame(height: 80, alignment: .top)
    }
}

/// How to calculate height of each view to fit into pdf
///   - each transaction row: height = 80 cgpoints
///   - header: body height 80 + 15 paddings * 2 + buffer(customize) 10 ~ = 120
///   - Total = (size.height -120) / 80  = count of transations for one pdf page
struct PDFStatementView: View {
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
        }
        .fileMover(isPresented: $showFileMover, file: pdfURL) { _ in
        }
    }

    var fileURL: URL? {
        let headerHeight: CGFloat = 110
        let pageBuffer: CGFloat = 20
        let pageCount = Int((PDFMaker.PageSize.a4().size.height - headerHeight - pageBuffer) / 80)
        let chunkTransactions = mockTransactions.chunked(into: pageCount)

        return try? PDFMaker.create(
            pageCount: chunkTransactions.count,
            pageContent: { pageIndex in
                ExportablePageView(
                    pageIndex: pageIndex,
                    transaction: chunkTransactions[pageIndex]
                )
            }
        )
    }
}

#Preview {
    PDFStatementView()
}
