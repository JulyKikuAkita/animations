//
//  AsyncImageViewerViewDemo.swift
//  animation
//
//  Standalone demo (not wired into the app's demo browser; preview-only).
//
//  Learning point
//  ──────────────
//  Smallest possible call site for the project's `AsyncImageViewer`
//  helper. Demonstrates the four moving pieces a caller has to wire
//  up:
//    1. `NavigationStack` wrapper — REQUIRED. `AsyncImageViewer`
//       presents the zoomed image via `.navigationTransition(.zoom)`,
//       which only works inside a NavigationStack.
//    2. `ForEach` over a remote-image collection rendered with
//       `AsyncImage(url:)`.
//    3. `.containerValue(\.activeViewID, image.id)` — tags each
//       grid cell so the viewer can identify which image was
//       tapped (read back as `activeViewID` in `updates:`).
//    4. An `overlay:` view with a dismiss button — `OverlayView`
//       is defined at the bottom of this file and is also reused
//       by [[AsyncImageViewerView+SkeletonviewDemo]] via module
//       scope.
//
//  Key APIs
//  ────────
//  • `AsyncImageViewer(content:overlay:updates:)` — project helper
//    at `Helpers/Layout/AsyncImageViewer.swift`. Internally uses
//    `Group(subviews:)` + `matchedTransitionSource` +
//    `navigationTransition(.zoom)`.
//  • `AsyncImage(url:content:placeholder:)` — first-party SwiftUI.
//  • `.containerValue(_:_:)` — iOS 18+, preferred over
//    PreferenceKey plumbing for ID-tagging subviews.
//  • `@Environment(\.dismiss)` inside `OverlayView` — dismisses the
//    zoomed presentation, not the surrounding NavigationStack.
//
//  How to apply
//  ────────────
//  Use this file as the template for any "tap a thumbnail → zoom
//  to full-screen" flow over remote URLs. If load times are slow
//  enough that ProgressView feels janky, see
//  [[AsyncImageViewerView+SkeletonviewDemo]]. If your sources are
//  local `UIImage`s and you need a custom dismiss gesture, see
//  [[PhotoGridViewIos26+TransitionEffect]] — it builds the whole
//  grid+hero pipeline from scratch instead of leaning on the helper.
//
//  See also
//  ────────
//  • Helpers/Layout/AsyncImageViewer.swift — the helper itself.
//  • AsyncImageViewerView+SkeletonviewDemo.swift — same demo with
//    a SkeletonView placeholder; depends on `OverlayView` defined
//    here.
//
import SwiftUI

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
                } updates: { _, _ in
                    // print(isPresented, activeViewID)
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
