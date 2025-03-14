//
//  DocumentDetailView.swift
//  DocumentScannerApp

import LocalAuthentication
import PDFKit
import SwiftUI

struct DocumentDetailView: View {
    /// View Properties
    @State private var isLoading: Bool = false
    @State private var showFileMover: Bool = false
    @State private var fileURL: URL?

    /// Lock screen properties
    @State private var isLockAvailable: Bool?
    @State private var isUnlocked: Bool = false

    /// Environment values
    @Namespace private var animationID
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scene

    var document: Document
    var body: some View {
        if let pages = document.pages?.sorted(by: { $0.pageIndex < $1.pageIndex }) {
            VStack(spacing: 10) {
                HeaderView()
                    .padding([.horizontal, .top], 15)

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
                FooterView()
            }
            .background(.black)
            .toolbarVisibility(.hidden, for: .navigationBar)
            .loadingScreen(status: $isLoading)
            .overlay {
                LockView()
            }
            .fileMover(isPresented: $showFileMover, file: fileURL) { result in
                if case let .failure(failure) = result {
                    /// Removing the temporary file
                    guard let fileURL else { return }
                    try? FileManager.default.removeItem(at: fileURL)
                    self.fileURL = nil
                }
            }
            .onAppear {
                guard document.isLocked else {
                    isUnlocked = true
                    return
                }

                let context = LAContext()
                isLockAvailable = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
            }
            .onChange(of: scene) { _, newValue in
                if newValue != .active, document.isLocked {
                    isUnlocked = false
                }
            }
        }
    }

    @ViewBuilder
    private func HeaderView() -> some View {
        Text(document.name)
            .font(.callout)
            .foregroundStyle(.white)
            .hSpacing(.center)
            .overlay(alignment: .trailing) {
                /// Lock button
                Button {
                    document.isLocked.toggle()
                    isUnlocked = !document.isLocked
                    try? context.save()
                } label: {
                    Image(systemName: document.isLocked ? "lock.fill" : "lock.open.fill")
                        .font(.title3)
                        .foregroundStyle(.purple)
                }
            }
    }

    @ViewBuilder
    private func FooterView() -> some View {
        HStack {
            Button(action: createAndShareDocument) {
                Image(systemName: "square.and.arrow.up.fill")
                    .font(.title3)
                    .foregroundStyle(.purple)
            }

            Spacer(minLength: 0)

            Button {
                dismiss()
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(0.3)) /// sleep for zoom transition to finish
                    context.delete(document)
                    try? context.save()
                }

            } label: {
                Image(systemName: "trash.fill")
                    .font(.title3)
                    .foregroundStyle(.red)
            }
        }
        .padding([.horizontal, .bottom], 15)
    }

    @ViewBuilder
    private func LockView() -> some View {
        if document.isLocked {
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()

                VStack(spacing: 4) {
                    if let isLockAvailable, !isLockAvailable {
                        Text("Please enable biometric access in Settings to unlock this document.")
                            .multilineTextAlignment(.center)
                            .frame(width: 200)

                    } else {
                        Image(systemName: "lock.fill")
                            .font(.largeTitle)

                        Text("Tap to unlock!")
                            .font(.callout)
                    }
                }
                .padding(15)
                .background(.bar, in: .rect(cornerRadius: 10))
                .contentShape(.rect)
                .onTapGesture(perform: authenticateUser)
            }
            .opacity(isUnlocked ? 0 : 1)
            .animation(snappy, value: isUnlocked)
        }
    }

    /// Converting SwiftData document into a PDF document
    private func createAndShareDocument() {
        guard let pages = document.pages?.sorted(by: { $0.pageIndex < $1.pageIndex }) else { return }

        isLoading = true
        /// creating pdf file in non-main thread
        Task.detached(priority: .userInitiated) { [document] in
            let pdfDocument = PDFDocument()
            for index in pages.indices {
                if let pageImage = UIImage(data: pages[index].pageData),
                   let pdfPage = PDFPage(image: pageImage)
                {
                    pdfDocument.insert(pdfPage, at: index)
                }
            }

            var pdfURL = FileManager.default.temporaryDirectory
            let fileName = "\(document.name).pdf"
            pdfURL.append(path: fileName)

            if pdfDocument.write(to: pdfURL) {
                /// update UI
                await MainActor.run { [pdfURL] in
                    fileURL = pdfURL
                    showFileMover = true
                    isLoading = false
                }
            }
        }
    }

    private func authenticateUser() {
        let context = LAContext()
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Locked document") { status, _ in
                DispatchQueue.main.async {
                    isUnlocked = status
                }
            }
        } else {
            isLockAvailable = false
            isUnlocked = false
        }
    }
}
