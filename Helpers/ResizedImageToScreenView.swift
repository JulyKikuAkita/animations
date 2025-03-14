//
//  ResizedImageToScreenView.swift
//  animation
//
// We need to downsized image to save memory in SwiftUI view

import SwiftUI

struct ResizedImageToScreenDemoView: View {
    var body: some View {
        NavigationStack {
            List {
                HStack {
                    ForEach(1 ... 3, id: \.self) { index in
                        let size = CGSize(width: 150, height: 150)
                        /// provide any large size image and monitor memory change when app startup
                        let id = "IMG_020\(index)"
                        let heicImage = UIImage(named: id)

                        ResizedImageToScreenView(id: id, image: heicImage, size: size) { image in
                            GeometryReader {
                                let size = $0.size

                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: size.width, height: size.height)
                                    .clipShape(.rect(cornerRadius: 10))
                            }
                            .frame(height: 150)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Resize image to input size")
    }
}

struct ResizedImageToScreenView<Content: View>: View {
    var id: String
    var image: UIImage?
    var size: CGSize
    @ViewBuilder var content: (Image) -> Content
    @State private var resizedImageView: Image?

    var body: some View {
        ZStack {
            if let resizedImageView {
                content(resizedImageView)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            guard resizedImageView == nil else { return }
            createDownsizedImage(image)
        }
        .onChange(of: image) { oldValue, newValue in
            guard oldValue != newValue else { return }
        }
    }

    private func createDownsizedImage(_ image: UIImage?) {
        if let cacheData = try? CacheManager.shared.get(id: id)?.data, let uiImage = UIImage(data: cacheData) {
            resizedImageView = .init(uiImage: uiImage)
        } else {
            guard let image else { return }
            let aspectSize = image.size.aspectFit(size)

            /// Creating image in non-main thread
            Task.detached(priority: .high) {
                let renderer = UIGraphicsImageRenderer(size: aspectSize)
                let resizedImage = renderer.image { _ in
                    image.draw(in: .init(origin: .zero, size: aspectSize))
                }

                /// Storing cached image
                if let jpegData = resizedImage.jpegData(compressionQuality: 1) {
                    /// Cache manger runs on main actor
                    await MainActor.run {
                        try? CacheManager.shared.insert(id: id, data: jpegData, expirationDays: 1)
                    }
                }
                /// Update image on main thread
                await MainActor.run {
                    resizedImageView = .init(uiImage: resizedImage)
                }
            }
        }
    }
}

/// return a new size based on the given aspect ratio
extension CGSize {
    func aspectFit(_ to: CGSize) -> CGSize {
        let scaleX = to.width / width
        let scaleY = to.height / height

        let aspectRatio = min(scaleX, scaleY)
        return .init(width: aspectRatio * width, height: aspectRatio * height)
    }
}

#Preview {
    ResizedImageToScreenDemoView()
}
