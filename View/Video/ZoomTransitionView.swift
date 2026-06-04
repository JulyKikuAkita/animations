//
//  ZoomTransitionView.swift
//  animation
//
//  Learning point
//  ──────────────
//  Apple-Photos-app-style "zoom into a thumbnail" transition: a
//  2-column grid of video thumbnails; tap any card to push into
//  a fullscreen detail view, with the thumbnail animating into
//  position via iOS 18's `matchedTransitionSource` +
//  `.navigationTransition(.zoom(...))`. Uses NavigationStack +
//  NavigationLink (not fullScreenCover) so back-swipe works
//  natively.
//
//  Three reusable mechanics
//  ────────────────────────
//    1. **`@Namespace` + `matchedTransitionSource(id:in:) { ... }`** —
//       attaches an animation token to each thumbnail, then the
//       detail view consumes the SAME id via
//       `.navigationTransition(.zoom(sourceID:in:))`. iOS 18
//       handles the cross-fade + scale + position animation,
//       reading both views' frames automatically. No manual
//       sourceRect tracking (compare to
//       `[[TransitionAnimationIOS26]]` which does it by hand).
//    2. **`@Bindable` + `@Observable` shared model** —
//       `VideoSharedModel` owns the array of `Video`s + thumbnail
//       generation. Both list and detail read it via
//       `@Environment(VideoSharedModel.self)`. Thumbnails are
//       generated lazily by `.task(priority: .high)` on first
//       appearance and cached on the model — so navigating
//       back doesn't regenerate them.
//    3. **`.matchedTransitionSource(id:in:) { $0.background(.clear).clipShape(...) }`** —
//       the trailing closure CONFIGURES the source's transition
//       presentation. Removing the background + applying the
//       same `clipShape` as the detail's hero means the zoom
//       animation cleanly morphs the rounded thumbnail into the
//       fullscreen card without a visible style change at the
//       hand-off.
//
//  Why `NoOpacityButtonStyle`
//  ──────────────────────────
//      struct NoOpacityButtonStyle: ButtonStyle {
//          func makeBody(configuration: Configuration) -> some View {
//              configuration.label
//          }
//      }
//
//  Wrapping each thumbnail in `NavigationLink` makes it a
//  Button. The DEFAULT button style applies a press-down opacity
//  fade, which fights the zoom transition (you see a flash of
//  faded thumbnail at the moment of tap). This style strips
//  press feedback entirely — fine because the zoom transition
//  itself IS the feedback.
//
//  Why `@Bindable var bindings = sharedModel`
//  ──────────────────────────────────────────
//  `@Observable` (iOS 17+) replaces `ObservableObject` /
//  `@Published`. To get a `Binding` to a property of an
//  `@Observable` object, you write `@Bindable` to derive
//  bindings on demand:
//      `$bindings.videos` — Binding<[Video]>
//      `$video` — Binding<Video> inside the ForEach
//  Without `@Bindable`, you can't pass mutable bindings to
//  child views.
//
//  Key APIs
//  ────────
//  • `@Namespace` + `.matchedTransitionSource(id:in:)` (iOS 18+) —
//    declarative source for navigation zoom.
//  • `.navigationTransition(.zoom(sourceID:in:))` — destination
//    side of the transition.
//  • `@Observable` + `@Bindable` (iOS 17+) — modern observation
//    + bindings.
//  • `.toolbarVisibility(.hidden, for: .navigationBar)` — hide
//    the nav bar on the detail view (we're going fullscreen
//    cinematic).
//  • `.task(priority: .high) { ... }` — eager thumbnail load
//    once the placeholder appears.
//
//  How to apply
//  ────────────
//  Use this whenever a list/grid → detail transition wants to
//  feel like the source CARD lifting off the screen, rather
//  than a side-slide push. Photos app, Apple TV+, App Store
//  product cards, music album grids — all use this pattern.
//
//  See also
//  ────────
//  • TransitionAnimationIOS26.swift — manual implementation of
//    the same effect using `fullScreenCover` + `sourceRect` +
//    `animateContent`. More work, more control.
//  • ZoomVideoDetailView.swift — the detail screen consumed by
//    the navigation zoom here.
//  • RippleTransitionDemoView.swift — shader-driven transition
//    (different category).
//

import SwiftUI

struct ZoomTransitionDemoView: View {
    var sharedModel = VideoSharedModel()
    @Namespace private var animation
    var body: some View {
        @Bindable var bindings = sharedModel
        GeometryReader {
            let screenSize: CGSize = $0.size

            NavigationStack {
                VStack(spacing: 0) {
                    headerView()

                    ScrollView(.vertical) {
                        LazyVGrid(columns: Array(repeating: GridItem(spacing: 10), count: 2),
                                  spacing: 10)
                        {
                            ForEach($bindings.videos) { $video in
                                NavigationLink(value: video) { /// Navigation is a form of button
                                    VideoCardView(screenSize: screenSize, video: $video)
                                        .environment(sharedModel)
                                        .frame(height: screenSize.height * 0.4)
                                        .matchedTransitionSource(id: video.id, in: animation) {
                                            $0
                                                .background(.clear)
                                                .clipShape(.rect(cornerRadius: 15))
                                        }
                                }
                                .buttonStyle(NoOpacityButtonStyle())
                            }
                        }
                        .padding(15)
                    }
                }
                .navigationDestination(for: Video.self) { video in
                    ZoomVideoDetailView(video: video, animation: animation)
                        .environment(sharedModel)
                        .toolbarVisibility(.hidden, for: .navigationBar)
                }
            }
        }
    }

    @ViewBuilder
    private func headerView() -> some View {
        HStack {
            Button {} label: {
                Image(systemName: "magnifyingglass")
                    .font(.title3)
            }

            Spacer(minLength: 0)

            Button {} label: {
                Image(systemName: "person.fill")
                    .font(.title3)
            }
        }
        .overlay {
            Text("Stories")
                .font(.title3.bold())
        }
        .foregroundStyle(Color.primary)
        .padding(15)
        .background(.ultraThinMaterial)
    }
}

struct VideoCardView: View {
    var screenSize: CGSize
    @Binding var video: Video
    @Environment(VideoSharedModel.self) private var sharedModel
    var body: some View {
        GeometryReader {
            let size = $0.size

            if let thumbnail = video.thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size.width, height: size.height)
                    .clipShape(.rect(cornerRadius: 15))
            } else {
                RoundedRectangle(cornerRadius: 15)
                    .fill(.fill)
                    .task(priority: .high) {
                        await sharedModel
                            .generateThumbnail($video, size: screenSize)
                    }
            }
        }
    }
}

/// button style  without opacity after click
struct NoOpacityButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

#Preview {
    ZoomTransitionDemoView()
}
