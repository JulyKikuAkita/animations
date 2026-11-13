//
//  MorphingIOS27Demo.swift
//  animation
//
//  Created on 11/10/26.
//
//  Learning points / Demo goals:
//  • Paging carousel: `containerRelativeFrame(.horizontal)` makes each page one
//    viewport wide and `scrollTargetBehavior(.paging)` snaps to it.
//  • The artwork does not scroll with the pages. Each page reserves a clear
//    `Rectangle` whose size is read with `onGeometryChange`; the real images live
//    in a separate stack in `.background`, driven by the scroll offset from
//    `onScrollGeometryChange` (`contentOffset.x + contentInsets.leading`).
//  • Inside that stack every image is counter-offset by its own `minX`, so all
//    images sit in the same spot and cross-fade by distance from the center.
//  • Gooey morph = blur + alpha threshold. `compositingGroup()` flattens the
//    cross-fading images into one layer, `.blur` smears their alpha, and the
//    `alphaThreshold` layer effect (AlphaThreshold.metal) cuts it back into a
//    single shape, so two half-faded images fuse into one blob.
//  • The blur follows a triangle over each page turn (0 → peak at 50% → 0), so
//    images are sharp at rest and only melt mid-swipe. Peak radius scales with
//    the container height so the effect holds across sizes.
//  • `maxSampleOffset` tells SwiftUI how far the shader may sample beyond each
//    pixel; `drawingGroup()` rasterizes the result off-screen with Metal.
//  • Parallax titles: `visualEffect` + `proxy.bounds(of: .scrollView)` shifts
//    the title against the scroll at 0.6× speed without extra state.
//  • Page indicator: each capsule's width and opacity are derived from
//    `|progress - index|`, so the active dot stretches continuously while dragging.
//  • iOS 26 glass button: `.buttonStyle(.glassProminent)`, `.buttonSizing(.flexible)`.

import SwiftUI

protocol MorphingItem: Identifiable {
    var id: String { get }
}

extension TVShow: MorphingItem {}

@available(iOS 26.0, *)
struct MorphingIOS27Demo: View {
    var body: some View {
        NavigationStack {
            VStack {
                MorphingIOS27ScrollView(items: tvShows, buttonText: "Continue") { item in
                    Image(item.artwork)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } title: { item in
                    Text(item.title)
                        .font(.title3.bold())
                        .lineLimit(1)
                } description: { item in
                    Text(item.content)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .padding(.bottom, 4)
                        .padding(.horizontal, 10)
                        .multilineTextAlignment(.center)
                } buttonAction: {}
                    .frame(height: 450)
            }
        }
    }
}

@available(iOS 26.0, *)
struct MorphingIOS27ScrollView<Preview: View, Title: View, Description: View, Item: MorphingItem>: View {
    var items: [Item]
    var buttonText: String
    @ContentBuilder var image: (Item) -> Preview
    @ContentBuilder var title: (Item) -> Title
    @ContentBuilder var description: (Item) -> Description
    var buttonAction: () -> Void
    /// View Properties
    @State private var offsetX: CGFloat = 0
    @State private var morphingContainer: CGSize = .zero
    @Environment(\.colorScheme) private var colorScheme
    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(items) { item in
                    VStack(spacing: 10) {
                        Rectangle()
                            .foregroundStyle(.clear)
                            .onGeometryChange(for: CGSize.self) {
                                $0.size
                            } action: { newValue in
                                morphingContainer = newValue
                            }
                            .padding(.bottom, 10)

                        title(item)
                            .padding(.horizontal, 15)
                            .frame(maxWidth: .infinity)
                            // on scroll speed movement animation effect
                            .visualEffect { content, proxy in
                                let minX = proxy.bounds(of: .scrollView)?.minX ?? 0
                                let speed: CGFloat = 0.6
                                let offset = -minX * min(speed, 1.0)
                                return content.offset(x: offset)
                            }

                        description(item)
                            .padding(.horizontal, 15)
                            .frame(maxWidth: .infinity)
                    }
                    .containerRelativeFrame(.horizontal)
                }
            }
        }
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.hidden)
        .background(alignment: .top) {
            if morphingContainer != .zero {
                morphingContainerView()
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 20) {
            bottomBar()
        }
        .onScrollGeometryChange(for: CGFloat.self) {
            $0.contentOffset.x + $0.contentInsets.leading
        } action: { _, newValue in
            offsetX = newValue
        }
    }

    @ContentBuilder
    private func morphingContainerView() -> some View {
        let blurRadius: CGFloat = morphingContainer.height / 3
        let rawProgress = max(min(offsetX / morphingContainer.width, CGFloat(items.count - 1)), 0)
        LazyHStack(spacing: 0) {
            ForEach(items) { item in
                image(item)
                    .padding(.horizontal, 15)
                    .padding(.top, 20)
                    .frame(width: morphingContainer.width, height: morphingContainer.height)
                    .compositingGroup()
                    .visualEffect { [morphingContainer] content, proxy in
                        let minX = proxy.frame(in: .named("BACKGROUND")).minX
                        let opacity = abs(minX / morphingContainer.width)

                        return content
                            .opacity(1 - opacity)
                            .offset(x: -minX)
                    }
            }
        }
        .offset(x: -offsetX)
        .frame(width: morphingContainer.width, height: morphingContainer.height, alignment: .leading)
        .clipped()
        .compositingGroup()
        // morphing effect
        .visualEffect { content, proxy in
            let progress = rawProgress.truncatingRemainder(dividingBy: 1)
            let blurProgress = progress > 0.5 ? abs(1.0 - progress) : progress
            return content
                .blur(radius: blurProgress * blurRadius)
                .layerEffect(
                    ShaderLibrary.alphaThreshold(),
                    maxSampleOffset: proxy.size
                )
        }
        .drawingGroup()
        .coordinateSpace(.named("BACKGROUND"))
    }

    private func bottomBar() -> some View {
        VStack(spacing: 15) {
            HStack(spacing: 4) {
                let progress = morphingContainer.width > 0 ? offsetX / morphingContainer.width : 0
                ForEach(items.indices, id: \.self) { index in
                    let indexProgress = max(min(abs(progress - CGFloat(index)), 1), 0)
                    let width = 20 - (15 * indexProgress)

                    Capsule()
                        .fill(colorScheme != .dark ? .black : .white)
                        .opacity(1 - (indexProgress * 0.65))
                        .frame(width: width)
                }
            }
            .frame(height: 5)

            Button(action: buttonAction) {
                Text(buttonText)
                    .fontWeight(.medium)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.glassProminent)
            .buttonSizing(.flexible)
            .buttonBorderShape(.capsule)
            .frame(maxWidth: 320)
        }
        .padding(.bottom, 18)
    }
}

@available(iOS 26.0, *)
#Preview {
    MorphingIOS27Demo()
}
