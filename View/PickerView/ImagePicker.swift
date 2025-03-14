//
//  ImagePicker.swift
//  animation
// https://www.youtube.com/watch?v=p1U13Ch8ykk&list=PLimqJDzPI-H97JcePxWNwBXJoGS-Ro3a-&index=31
import PhotosUI
import SwiftUI

struct ImagePickerDemo: View {
    var body: some View {
        NavigationStack {
            VStack {
                ImagePicker(title: "Drag & Drop", subTitle: "Tap to add an Image", systemImage: "square.and.arrow.up", tint: .blue) { _ in
                }
                .frame(maxWidth: 300, maxHeight: 250)
                .padding(.top, 20)

                Spacer()
            }
            .padding()
            .navigationTitle("Image Picker")
        }
    }
}

/// Custom Image Picker
/// Included drag & drop
struct ImagePicker: View {
    var title: String
    var subTitle: String
    var systemImage: String
    var tint: Color
    var onImageChange: (UIImage) -> Void

    /// View Properties
    @State private var showImagePicker: Bool = false
    @State private var photoItem: PhotosPickerItem?
    /// Preview image
    @State private var previewImage: UIImage?
    /// Loading status
    @State private var isLoading: Bool = false

    var body: some View {
        GeometryReader {
            let size = $0.size

            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.largeTitle)
                    .imageScale(.large)
                    .foregroundStyle(tint)

                Text(title)
                    .font(.callout)
                    .padding(.top, 15)

                Text(subTitle)
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            /// displaying preview image if any
            .opacity(previewImage == nil ? 0 : 1)
            .frame(width: size.width, height: size.height)
            .overlay {
                if let previewImage {
                    Image(uiImage: previewImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(15)
                }
            }
            /// displaying loading UI
            .overlay {
                if isLoading {
                    ProgressView()
                        .padding(10)
                        .background(.ultraThinMaterial, in: .rect(cornerRadius: 5))
                }
            }
            /// Animating changes
            .animation(.snappy, value: isLoading)
            .animation(.snappy, value: previewImage)
            .contentShape(.rect)
            /// implementing drop action & retrieving dropped image
            .dropDestination(for: Data.self, action: { items, _ in
                if let firstItem = items.first,
                   let droppedImage = UIImage(data: firstItem)
                {
                    /// sending the image using the callback
                    generatingImageThumbnail(droppedImage, size)
                    onImageChange(droppedImage)
                    return true
                }
                return false
            }, isTargeted: { _ in

            })
            .onTapGesture {
                showImagePicker.toggle()
            }
            /// Implementing manual image picker
            .photosPicker(isPresented: $showImagePicker, selection: $photoItem)
            /// lets process the selected image
            .optionalViewModifier { contentView in
                if #available(iOS 17, *) {
                    contentView
                        .onChange(of: photoItem) { _, newValue in
                            if let newValue {
                                extractImage(newValue, size)
                            }
                        }
                } else {
                    contentView
                        .onChange(of: photoItem) { newValue in
                            if let newValue {
                                extractImage(newValue, size)
                            }
                        }
                }
            }
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .fill(tint.opacity(0.08).gradient)

                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(tint, style: .init(lineWidth: 1, dash: [12]))
                        .padding(1)
                }
            }
        }
    }

    func extractImage(_ photoItem: PhotosPickerItem, _ viewSize: CGSize) {
        Task.detached {
            guard let imageData = try? await photoItem.loadTransferable(type: Data.self) else { return }

            // UI must update on the main thread
            await MainActor.run {
                if let selectedImage = UIImage(data: imageData) {
                    /// Creating preview
                    generatingImageThumbnail(selectedImage, viewSize)
                    /// Send original image to callback
                    onImageChange(selectedImage)
                }

                /// clearing photoitem
                self.photoItem = nil
            }
        }
    }

    /// Creating Image Thumbnail
    func generatingImageThumbnail(_ image: UIImage, _ size: CGSize) {
        Task.detached {
            let thumbnailImage = await image.byPreparingThumbnail(ofSize: size)
            /// UI must be updated on Main thread
            await MainActor.run {
                previewImage = thumbnailImage
            }
        }
    }
}

/// Custom view modifier
extension View {
    @ViewBuilder
    func optionalViewModifier(@ViewBuilder content: @escaping (Self) -> some View) -> some View {
        content(self)
    }
}

#Preview {
    ImagePickerDemo()
}
