//
//  SwipeableCustomTabbar.swift
//  animation
//
//  Created on 6/15/26.

import SwiftUI

@available(iOS 26.0, *)
struct SwipeableCustomTabBarDemoView: View {
    @State private var pagerPosition: ScrollPosition = .init()
    @State private var pagerContainerSize: CGSize = .zero
    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 15) {
                ForEach(dummyBeamColors.dropLast(2), id: \.self) { color in
                    ConcentricRectangle(corners: .concentric, isUniform: true)
                        .fill(color)
                        .containerRelativeFrame(.horizontal)
                        .ignoresSafeArea()
                }
            }
        }
        /// all scroll behavior is controlled by SwipeableTabBar
        .scrollDisabled(true)
        .scrollIndicators(.hidden)
        .scrollPosition($pagerPosition)
        .onScrollGeometryChange(for: CGSize.self, of: {
            $0.containerSize
        }, action: { _, newValue in
            pagerContainerSize = newValue
        })
        .overlay(alignment: .bottom) {
            customBottomBar()
        }
    }

    @ContentBuilder
    private func customBottomBar() -> some View {
        GlassEffectContainer(spacing: 10) {
            HStack(spacing: 10) {
                Button {} label: {
                    Image(systemName: "tray.badge.fill")
                        .font(.title3)
                        .frame(width: 30, height: 40)
                }

                SwipeableTabBar {
                    ForEach(TabItem.allCases, id: \.rawValue) { tab in
                        HStack(spacing: 6) {
                            Image(systemName: tab.symbol)
                            Text(tab.rawValue.capitalized)
                        }
                    }
                } onProgressChange: { progress in
                    let pagerWidth = pagerContainerSize.width
                    let pagerSpacing: CGFloat = 15
                    let newPagerPos: CGFloat = (pagerWidth + pagerSpacing) * progress
                    pagerPosition.scrollTo(x: newPagerPos)
                }

                Button {} label: {
                    Image(systemName: "plus")
                        .font(.title3)
                        .frame(width: 30, height: 40)
                }
                .buttonStyle(.glassProminent)
            }
            .padding(.horizontal, 20)
        }
    }

    enum TabItem: String, CaseIterable {
        case one, two, three, four
        var symbol: String {
            switch self {
            case .one: "calendar"
            case .two: "chart.pie.fill"
            case .three: "gear"
            case .four: "person.crop.circle"
            }
        }
    }
}

@available(iOS 26.0, *)
struct SwipeableTabBar<Content: View>: View {
    // use @ViewBuilder if xcode26
    @ContentBuilder var tabs: Content
    var onProgressChange: (CGFloat) -> Void
    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(subviews: tabs) { subview in
                    SampleTabItem {
                        subview
                    }
                }
            }
        }
        .frame(height: 45)
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.hidden)
        .onScrollGeometryChange(for: CGFloat.self, of: {
            let containerSize = $0.containerSize.width
            let offset = $0.contentOffset.x + $0.contentInsets.leading
            let progress: CGFloat = offset / containerSize
            return progress
        }, action: { _, newValue in
            onProgressChange(newValue)
        })
        .clipShape(.capsule)
        .padding(5)
        .glassEffect(.clear.interactive(false), in: .capsule)
    }
}

@available(iOS 26.0, *)
private struct SampleTabItem<Content: View>: View {
    @ContentBuilder var content: Content
    /// View Properties
    @Environment(\.colorScheme) private var colorScheme
    var body: some View {
        GeometryReader {
            let rect = $0.frame(in: .scrollView(axis: .horizontal))
            let minX = rect.minX

            let minWidth: CGFloat = 60
            let distanceBetween: CGFloat = -rect.width / 4.5

            let width: CGFloat = minX <= 0 ? (rect.width + minX) : (rect.width - minX)
            let progress: CGFloat = 1 - (width / rect.width).limited
            let cappedWidth: CGFloat = max(width + (progress * distanceBetween), minWidth)

            let contentOpacity = calculateContentOpacity(progress, minX: minX)
            let containerOpacity = calculateContainerOpacity(progress, minX: minX)

            content
                .foregroundStyle(foreground)
                .compositingGroup()
                .blur(radius: contentOpacity * 5)
                .opacity(1 - contentOpacity)
                .frame(width: rect.width, height: rect.height)
                .frame(width: cappedWidth)
                .clipShape(.capsule)
                .glassEffect(.regular.tint(background.opacity(0.1)), in: .capsule)
                .opacity(1 - containerOpacity)
                .offset(x: minX <= 0 ? -minX : (rect.width - minX - cappedWidth))
        }
        .containerRelativeFrame(.horizontal)
        .frame(maxHeight: .infinity)
    }

    private nonisolated
    func calculateContentOpacity(_ progress: CGFloat, minX: CGFloat) -> CGFloat {
        if minX < 0 {
            return progress > 0.35 ? ((progress - 0.35) / 0.1).limited : 0
        }
        let reverseProgress = abs(progress - 1)
        return reverseProgress > 0.5 ? (1 - ((reverseProgress - 0.5) / 0.1).limited) : 1
    }

    private nonisolated
    func calculateContainerOpacity(_ progress: CGFloat, minX _: CGFloat) -> CGFloat {
        let reverseProgress: CGFloat = abs(progress - 1)
        return reverseProgress > 0.35 ? (1 - ((reverseProgress - 0.35) / 0.1).limited) : 1
    }

    var background: Color {
        colorScheme == .dark ? .white : .black
    }

    var foreground: Color {
        colorScheme == .dark ? .black : .white
    }
}

@available(iOS 26.0, *)
#Preview {
    SwipeableCustomTabBarDemoView()
}

private extension BinaryFloatingPoint {
    var limited: Self {
        max(min(self, 1), 0)
    }
}
