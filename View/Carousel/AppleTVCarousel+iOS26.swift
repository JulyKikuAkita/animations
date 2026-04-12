//
//  AppleTVCarousel+iOS26.swift
//  animation
//
//  Created on 3/14/26.
// Apple TV app carousel cards:
// - using backgroundExtensionEffect to extend the image to nearest safe area -> create a background extension effect
//

import SwiftUI

@available(iOS 26.0, *)
struct AppleTVCarouselDemoView: View {
    @State private var activeIndex: Int = 0
    @State private var scrollPhase: ScrollPhase = .idle
    @State private var verticalOffset: CGFloat = 0
    var body: some View {
        ScrollView(.vertical) {
            VStack {
                AppleTVCarousel {
                    ForEach(tvShows) { show in
                        Image(show.artwork)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .overlay(alignment: .bottom) {
                                bottomContent(show)
                            }
                    }
                } scrollProgress: { progress in
                    activeIndex = min(Int(progress.rounded()), tvShows.count - 1)
                }
                .onScrollPhaseChange { _, newPhase in
                    scrollPhase = newPhase
                }
                .frame(height: 500 + verticalOffset) /// create vertical stretching effect
                .offset(y: -verticalOffset)
            }
        }
        .onScrollGeometryChange(for: CGFloat.self, of: {
            $0.contentOffset.y + $0.contentInsets.top
        }, action: { _, newValue in
            verticalOffset = max(-newValue, 0)
        })
        .backgroundExtensionEffect()
    }

    func bottomContent(_ show: TVShow) -> some View {
        let isActive: Bool = tvShows[activeIndex].id == show.id
        return VStack(spacing: 0) {
            Text(show.title)
                .font(.system(size: 50, weight: .black))

            Text(show.subtitle)
                .font(.system(size: 25, weight: .black))

            Text(show.content)
                .font(.callout)
                .fontWeight(.medium)
                .padding(.top, 10)

            /// Dummy buttons
            HStack(spacing: 10) {
                Button {} label: {
                    HStack(spacing: 10) {
                        Image(systemName: "play.fill")
                        Text("Play")
                    }
                    .frame(width: 150, height: 45)
                    .foregroundStyle(.black)
                    .background(.white, in: .capsule)
                }

                Button {} label: {
                    HStack(spacing: 10) {
                        Image(systemName: "plus")
                    }
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                    .frame(width: 45, height: 45)
                    .background(.white.tertiary, in: .circle)
                }
            }
            .padding(.top, 15)
        }
        .foregroundStyle(.white)
        .compositingGroup()
        .padding(.bottom, 35)
        /// Animating only active card
        .animation(isActive ? .linear(duration: 0.18) : .none) { content in
            content
                .opacity(scrollPhase != .interacting ? 1 : 0)
        }
        .opacity(isActive ? 1 : 0)
    }
}

@available(iOS 26.0, *)
struct AppleTVCarousel<Content: View>: View {
    var movement: CGFloat = 60
    @ViewBuilder var content: Content
    var scrollProgress: (CGFloat) -> Void
    @State private var progress: CGFloat = 0
    var body: some View {
        GeometryReader {
            let size = $0.size

            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    Group(subviews: content) { collection in
                        ForEach(Array(collection.enumerated()), id: \.offset) { index, subview in
                            let isLast: Bool = index == collection.count - 1
                            /// Converting global progress into individual progress for opacity value
                            let opacity = isLast ? 0 : max(min(progress - CGFloat(index), 1), 0)
                            ZStack {
                                subview
                                    .frame(width: size.width, height: size.height)
                                    .clipped()
                                    .backgroundExtensionEffect()
                                    .safeAreaPadding(.horizontal, movement + 10)
                                    .mask {
                                        /// masking only horizontal direction
                                        Rectangle()
                                            .ignoresSafeArea()
                                    }
                            }
                            .frame(width: size.width, height: size.height)
                            .compositingGroup()
                            .opacity(1 - opacity)
                            /// mimic ZStack effect
                            .visualEffect { [movement] content, proxy in
                                let minX = proxy.frame(in: .scrollView(axis: .horizontal)).minX
                                /// Converting minX to progress [-1, 1] for offset value
                                let movementProgress = (minX / size.width).constrained(to: -1 ... 1)
                                return content
                                    .offset(x: -minX)
                                    .offset(x: movement * movementProgress)
                            }
                            .zIndex(Double(-index))
                        }
                    }
                }
            }
            .scrollTargetBehavior(.paging)
            .scrollIndicators(.hidden)
            .onScrollGeometryChange(for: CGFloat.self) {
                $0.contentOffset.x + $0.contentInsets.leading
            } action: { _, newValue in
                progress = max(newValue / size.width, 0)
                scrollProgress(progress)
            }
        }
    }
}

@available(iOS 26.0, *)
#Preview {
    AppleTVCarouselDemoView()
}

public extension CGFloat {
    /// Constrains the value to a closed range.
    ///
    /// Usage:
    ///   let progress = (translation / height).constrained(to: 0...1)
    func constrained(to range: ClosedRange<Self>) -> Self {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
