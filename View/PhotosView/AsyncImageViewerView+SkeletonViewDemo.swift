//
//  AsyncImageViewerView+SkeletonViewDemo.swift
//  animation
//
//  Standalone demo (not wired into the app's demo browser; preview-only).
//
//        1. The `displaySkeleton` toggle in the success closure
//           (line ~25) is labelled "demo purpose only, we only need
//           the view in placeholder" — confirm whether the
//           skeleton-in-content branch still earns its keep, or
//           whether the `placeholder:` branch alone is enough.
//
//  Learning point
//  ──────────────
//  Variant of [[AsyncImageViewerViewDemo]] that swaps the gray
//  ProgressView placeholder for a `SkeletonView` shimmer. Two
//  spots use the skeleton:
//    • `placeholder:` closure — runs while the URL is loading.
//      This is the "real" use case.
//    • Success closure, gated on `displaySkeleton`. Stays on until
//      `AsyncImageViewer.updates(_:_:)` reports `isPresented = true`
//      (an image was tapped → enlarged), then flips off so the real
//      image renders. Lets the grid keep its skeleton look until
//      the user opens an image — handy for placeholder-heavy demos.
//
//  Key APIs
//  ────────
//  • `SkeletonView(.rect(cornerRadius:))` — project helper that
//    animates a shimmering gradient mask. See View/SkeletonView.
//  • `updates:` closure on `AsyncImageViewer` — fires whenever the
//    enlarged presentation toggles. Use it to drive grid-side state.
//  • `OverlayView` — defined in [[AsyncImageViewerViewDemo]] and
//    reused here via module scope; do not duplicate.
//
//  How to apply
//  ────────────
//  Reach for this when image loads are slow enough that a plain
//  ProgressView feels janky (large remote assets, slow networks).
//  The skeleton-in-success-closure path is optional — only keep it
//  if you want the placeholder look to PERSIST past load until some
//  user action.
//
//  See also
//  ────────
//  • AsyncImageViewerViewDemo.swift — simpler variant; defines
//    `OverlayView` used here.
//  • Helpers/Layout/AsyncImageViewer.swift — the underlying helper.
//
import SwiftUI

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
