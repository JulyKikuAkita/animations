//
//  MorphingIOS27Demo.swift
//  animation
//
//  Created on 11/10/26.

import SwiftUI

protocol MorphingItem: Identifiable {
    var id: String { get }
}

extension TVShow: MorphingItem {}

@available(iOS 26.0, *)
struct MorphingIOS27Demo: View {
    @State private var showSheet: Bool = false
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
                        let minX = proxy.frame(in: .named("BACKGROUP")).minX
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
                let progress = offsetX / morphingContainer.width
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
