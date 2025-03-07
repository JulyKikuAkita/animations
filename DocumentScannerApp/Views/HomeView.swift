//
//  HomeView.swift
//  DocumentScannerApp
// VisionKit API provides access to a viewController called "VNDocumentCameraViewController",
// which provides basic scanning features to capture documents and extract result as image
//
import SwiftUI
import SwiftData
import VisionKit

struct HomeView: View {
    /// View Properties
    @State private var showScannerView: Bool = false
    @State private var scanDocument: VNDocumentCameraScan?
    @State private var documentName: String = "New Document"
    @State private var askDocumentName: Bool = false
    @State private var isLoading: Bool = false
    @Query(sort: [.init(\Document.createdAt, order: .reverse)], animation: .snappy(duration: 0.25, extraBounce: 0)) private var documents: [Document]

    /// Environment values
    @Namespace private var animationID
    @Environment(\.modelContext) private var context
    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                LazyVGrid(columns: Array(repeating: GridItem(spacing: 10), count: 2), spacing: 15) {
                    ForEach(documents) { document in
                        NavigationLink {
                            DocumentDetailView(document: document)
                                .navigationTransition(.zoom(sourceID: document.uniqueViewID, in: animationID))
                        } label: {
                            DocumentCardView(document: document, animationID: animationID)
                                .foregroundStyle(Color.primary)
                        }
                    }
                }
                .padding(15)
            }
            .navigationTitle("Document's")
            .safeAreaInset(edge: .bottom) {
                createButton()
            }
        }
        .fullScreenCover(isPresented: $showScannerView) { /// won't work in simulator
            ScannerView { error in

            } didCancel: {
                /// Closing View
                showScannerView = false
            } didFinish: { scan in
                scanDocument = scan
                showScannerView = false
                askDocumentName = true
            }
            .ignoresSafeArea()
        }
        .alert("Document Name", isPresented: $askDocumentName) {
            TextField("New Document", text: $documentName)

            Button("Save") {
                createDocuments()
            }
            .disabled(documentName.isEmpty)
        }
        .loadingScreen(status: $isLoading)
    }

    /// Custom scan document button
    @ViewBuilder
    private func createButton() -> some View {
        Button {
            showScannerView.toggle()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "document.viewfinder.fill")
                    .font(.title3)

                Text("Scan Documents")
            }
            .foregroundColor(.white)
            .fontWeight(.semibold)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(.purple.gradient, in: .capsule)
        }
        .hSpacing(.center)
        .padding(.vertical, 10)
        /// Custom progressive background effect
        .background {
            Rectangle()
                .fill(.background)
                .mask {
                    Rectangle()
                        .fill(.linearGradient(colors: [
                            .white.opacity(0),
                            .white.opacity(0.5),
                            .white,
                            .white
                        ], startPoint: .top, endPoint: .bottom))
                }
                .ignoresSafeArea()
        }
    }

    private func createDocuments() {
        guard let scanDocument else { return }
        isLoading = true

        Task.detached(priority: .userInitiated) { [documentName] in
            let document = Document(name: documentName)
            var pages: [DocumentPage] = []

            for pageIndex in 0..<scanDocument.pageCount {
                let pageImage = scanDocument.imageOfPage(at: pageIndex)

                /// compression is 0(most)..1(least)
                guard let pageData = pageImage.jpegData(compressionQuality: 0.65) else { return }
                let documentPage = DocumentPage(document: document, pageIndex: pageIndex, pageData: pageData)
                pages.append(documentPage)
            }

            document.pages = pages

            /// Saving data on main thread
            await MainActor.run {
                context.insert(document)
                try? context.save()
                /// Resetting data
                self.scanDocument = nil
                isLoading = false
                self.documentName = "New Document"
            }
        }
    }
}
