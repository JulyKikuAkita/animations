//
//  AsyncImageAndSkeletonViewDemo.swift
//  animation
//
import SwiftUI

@main
struct SkeletonViewDemo: App {
    var body: some Scene {
        WindowGroup {
            AsyncImageAndSkeletonViewDemo()
        }
    }
}

struct AsyncImageAndSkeletonViewDemo: View {
    @State private var displaySkeleton: Bool = true
    var body: some View {
        NavigationStack {
            VStack {
                AsyncImageViewer {
                    ForEach(PexelsImages) { image in
                        AsyncImage(url: URL(string: image.link)) { image in
                            if displaySkeleton { // demo purpose only, we only need the view in placeholder
                                SkeletonView(.rect(cornerRadius: 10))
                            } else {
                                image
                                    .resizable() // AsyncImageViewer handles fit/fill resize
                            }
                        } placeholder: {
                            SkeletonView(.rect(cornerRadius: 10))
                                .frame(height: 200)
                        }
                        .containerValue(\.activeViewID, image.id)
                    }
                } overlay: {
                    OverlayView()
                } updates: { isPresented, _ in
                    // print(isPresented, activeViewID)
                    if isPresented {
                        displaySkeleton = false
                    }
                }
            }
            .padding(15)
            .navigationTitle("Image Viewer")
        }
    }
}

#Preview {
    AsyncImageAndSkeletonViewDemo()
}
