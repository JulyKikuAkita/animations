//
//  AsyncImageViewerViewDemo.swift
//  animation
//
import SwiftUI

// Note: NavigationStack is required when calling AsyncImageViewer for zoom transition api
struct AsyncImageViewerViewDemo: View {
    var body: some View {
        NavigationStack {
            VStack {
                AsyncImageViewer {
                    ForEach(PexelsImages) { image in
                        AsyncImage(url: URL(string: image.link)) { image in
                            image
                                .resizable() // AsyncImageViewer handles fit/fill resize
                        } placeholder: {
                            Rectangle()
                                .fill(.gray.opacity(0.4))
                                .overlay {
                                    ProgressView()
                                        .tint(.blue)
                                        .scaleEffect(0.7)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                }
                        }
                        .containerValue(\.activeViewID, image.id)
                    }
                } overlay: {
                    OverlayView()
                } updates: { isPresented, activeViewID in
                    //print(isPresented, activeViewID)
                }
            }
            .padding(15)
            .navigationTitle("Image Viewer")
        }
    }
}

struct OverlayView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(.ultraThinMaterial)
                    .padding(10)
                    .contentShape(.rect)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 0)
        }
        .padding(15)
    }
}

#Preview {
    AsyncImageViewerViewDemo()
}
