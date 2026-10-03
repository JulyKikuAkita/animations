//
//  HeaderScrollAppleMapsIOS27Demo.swift
//  animation
//
//  Created on 10/2/26.
// Apple Maps Interactive Sheet Header Scroll animation

// Learning notes:
// - One driver value: `sheetProgress` is the sheet's live height normalized to 0...1 between the
//   min detent (80) and the largest detent. Every effect (header size, title scale, padding,
//   shadow, background opacity) derives from it, so they all track the drag gesture in lockstep.
// - Explicit height detents: the largest detent is measured from the presenting view via
//   onGeometryChange, and the center detent is the midpoint. Fixed heights keep the progress math
//   deterministic, unlike `.medium`/`.large` whose heights vary by device.
// - Maps-style persistence: `.presentationBackgroundInteraction(.enabled(upThrough:))` keeps the
//   view behind the sheet interactive up to the center detent, and `.interactiveDismissDisabled()`
//   stops a swipe-down from dismissing it, so the sheet only collapses to the min detent.
// - Phased sub-progress: one 0...1 value is split into ranges so effects happen in stages.
//   `centerProgress` covers min -> center, `shadowProgress` covers center -> largest, and the
//   background fades from 0.49 to 0.69, so the sheet stays glass until it passes the center detent.
// - Header lives inside the scroll content (`.safeAreaInset(edge: .top)`), so it scrolls away with
//   the content. `max(..., 1)` on its size avoids a zero-size frame at progress 0.
// - Minimized bar trigger: `contentOffset.y + contentInsets.top` gives an offset that is 0 at rest.
//   Once it exceeds the current header height + spacing, the header has scrolled off and the glass
//   bar overlay is shown. It is a Bool so the swap springs instead of tracking the finger.
// - Scoped animation (`.animation(_:body:)`): only the opacity inside the closure animates. Frame
//   and scale changes driven by `sheetProgress` stay un-animated so they follow the gesture exactly.
// - `scaleEffect` does not change layout size, so the title stack uses negative spacing at small
//   progress to pull the caption up under the visually shrunk title. `.geometryGroup()` makes the
//   stack resolve its geometry as one unit so children don't animate their positions independently.
// - `.compositingGroup()` before `.shadow` renders the image first and shadows the result; a large
//   radius with negative y offset reads as a tinted glow behind the header rather than a drop shadow.
// - Overlays sit outside the ScrollView, so the minimized bar and dismiss button stay pinned to the
//   sheet's top edge regardless of scroll position.

import SwiftUI

@available(iOS 26.0, *)
struct HeaderScrollIOS27Demo: View {
    @State private var sheetConfig: CustomSheetConfig = .init()
    @State private var isPresented: Bool = false
    var body: some View {
        VStack {}
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onGeometryChange(for: CGSize.self, of: {
                $0.size
            }, action: { newValue in
                sheetConfig.largestDetentHeight = newValue.height - 10
            })
            .sheet(isPresented: $isPresented) {
                CustomSheetView(config: $sheetConfig, title: "Favorites", caption: " 0 Place") {
                    Image(.nanachiPaint)
                } content: {
                    Rectangle()
                        .fill(.clear)
                        .frame(height: 2000)
                }
            }
            .onAppear {
                isPresented = true
            }
    }
}

@available(iOS 26.0, *)
private struct CustomSheetView<Content: View>: View {
    @Binding var config: CustomSheetConfig
    var title: String
    var caption: String
    @ContentBuilder var headerImage: Image
    @ContentBuilder var content: Content
    /// View Properties
    @State private var sheetProgress: CGFloat = 0
    @State private var isHeaderBarVisible: Bool = false
    @Environment(\.dismiss) var dismiss
    var body: some View {
        ScrollView(.vertical) {
            content
                .safeAreaInset(edge: .top, spacing: 0) {
                    headerView()
                }
        }
        .presentationDetents([.height(Constants.minHeight), centerDetent, largestDetent])
        .presentationBackgroundInteraction(.enabled(upThrough: centerDetent))
        .interactiveDismissDisabled()
        .presentationBackground {
            let opacity = sheetProgress > 0.49 ? (sheetProgress - 0.49) / 0.2 : 0
            Rectangle()
                .fill(.windowBackground)
                .opacity(opacity)
        }
        .onGeometryChange(for: CGSize.self, of: {
            $0.size
        }, action: { newValue in
            let progress = (newValue.height - 80) / (config.largestDetentHeight - 80)
            let cappedProgress = min(1, max(0, progress))
            sheetProgress = cappedProgress
        })
        .onScrollGeometryChange(for: CGFloat.self,
                                of: { $0.contentOffset.y + $0.contentInsets.top },
                                action: { _, newValue in
                                    let adjustedHeaderHeight = config.headerMaxSize.height * sheetProgress
                                    let spacing: CGFloat = 20
                                    let adjustOffset = newValue - (adjustedHeaderHeight + spacing)
                                    isHeaderBarVisible = adjustOffset > 0
                                })
        .overlay(alignment: .top) {
            minimizedHeaderBar()
        }
        .overlay(alignment: .topTrailing) {
            dismissButton()
        }
//        /// xcode 27.1 iPhone Duo only
//        .presentationCompactAdaptation(.sheet)
//        .presentationPlacement(.center)
//        .toolbarVerticalBehavior(.disabled)
    }

    private func headerView() -> some View {
        let centerProgress = sheetProgress < 0.5 ? (sheetProgress / 0.5) : 1
        let shadowProgress = sheetProgress > 0.5 ? (sheetProgress - 0.5) / 0.5 : 0
        let blurRadis = (1 - centerProgress) * 5

        return VStack(spacing: 0) {
            headerImage
                .resizable()
                .aspectRatio(contentMode: config.headerImageAspect)
                .frame(width: headerSize.width, height: headerSize.height)
                .compositingGroup()
                .shadow(
                    color: config.headerTint.opacity(shadowProgress),
                    radius: 100, x: 0, y: -70
                )

            VStack(spacing: -10 + (10 * sheetProgress)) {
                Text(title)
                    .font(.title)
                    .fontWeight(.bold)
                    .scaleEffect(0.7 + (0.3 * sheetProgress), anchor: .top)

                Text(caption)
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            .geometryGroup()
            .padding(.top, sheetProgress * 15)
        }
        .animation(.iSpring()) {
            $0.opacity(isHeaderBarVisible ? 0 : 1)
        }
        .frame(minHeight: 80)
        .padding(.top, centerProgress * 25)
    }

    private func minimizedHeaderBar() -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.callout)

            Text(caption)
                .font(.caption)
                .foregroundStyle(.gray)
        }
        .padding(.top, 10)
        .frame(maxWidth: .infinity)
        .frame(height: Constants.minHeight)
        .glassEffect(.regular, in: .rect)
        .compositingGroup()
        .animation(.iSpring()) {
            $0.opacity(isHeaderBarVisible ? 1 : 0)
        }
    }

    private func dismissButton() -> some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.title3)
                .frame(width: 20, height: 30)
        }
        .buttonStyle(.glass)
        /// xcode 27.1 iPhone Duo only api
//        .frame(height: 80)
//        .frame(maxWidth: .infinity, alignment: .trailing)
//        .visualEffect({ content, proxy in
//            let regions = proxy.reservedRegions(kind: .occlusion)
//            let width = proxy.size.width
//            let pushToLeading = regions.contains(where: {
//                $0.frame.minX > (width / 2)
//            })
//            return content.offseT(x: pushToLeading ? -(width - 45) : 0)
//        })
//        .padding(.trailing, 15)
        .frame(height: Constants.minHeight)
        .padding(.trailing, 15)
    }

    private var headerSize: CGSize {
        CGSize(width: max(config.headerMaxSize.width * sheetProgress, 1),
               height: max(config.headerMaxSize.height * sheetProgress, 1))
    }

    private var centerDetent: PresentationDetent {
        .height((config.largestDetentHeight + Constants.minHeight) / 2)
    }

    private var largestDetent: PresentationDetent {
        .height(config.largestDetentHeight)
    }
}

private enum Constants {
    static let minHeight: CGFloat = 80
}

struct CustomSheetConfig {
    var headerMaxSize: CGSize = .init(width: 180, height: 180)
    var headerImageAspect: ContentMode = .fill
    var headerCornerRadius: CGFloat = 20
    var headerTint: Color = .yellow
    var largestDetentHeight: CGFloat = .infinity
}

@available(iOS 26.0, *)
#Preview {
    HeaderScrollIOS27Demo()
}
