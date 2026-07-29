//
//  TextExpandableCustomTabbar.swift
//  animation
//
//  Created on 7/29/26.

import SwiftUI

struct TextExpandableTabBarDemo: View {
    @State private var scrollProgress: CGFloat = 0
    @State private var scrollPosition: ScrollPosition = .init()
    @State private var containerSize: CGSize = .zero
    var body: some View {
        VStack {
            HStack {
                Button {} label: {
                    Image(systemName: "arrow.left")
                }

                Spacer(minLength: 0)

                Button {} label: {
                    Image(systemName: "magnifyingglass")
                }
            }
            .font(.title3)
            .overlay {
                Text("History")
                    .fontWeight(.semibold)
            }
            .foregroundStyle(Color.primary)
            .padding(15)

            XStyleTabBar<XTab>(progress: scrollProgress) { tab in
                withAnimation(.easeInOut(duration: 0.25)) {
                    let index = XTab.allCases.firstIndex(of: tab) ?? 0
                    scrollPosition.scrollTo(x: CGFloat(index) * containerSize.width)
                }
            }
            .padding(.horizontal, 25)
            .background(alignment: .bottom) {
                Rectangle()
                    .fill(.gray.tertiary)
                    .frame(height: 1)
            }

            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(XTab.allCases, id: \.rawValue) { tab in
                        Text(tab.rawValue)
                            .containerRelativeFrame(.horizontal)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.paging)
            .scrollPosition($scrollPosition)
            .onScrollGeometryChange(for: CGFloat.self) {
                ($0.contentOffset.x + $0.contentInsets.leading) / $0.containerSize.width
            } action: { _, newValue in
                scrollProgress = newValue
            }
            .onScrollGeometryChange(for: CGSize.self) {
                $0.containerSize
            } action: { _, newValue in
                containerSize = newValue
            }

            Spacer(minLength: 0)
        }
    }
}

protocol XStyleTabItem: CaseIterable, Hashable {
    var title: String { get }
    var symbolImage: String { get }
}

extension XTab: XStyleTabItem {}

struct XStyleTabBar<Value: XStyleTabItem>: View {
    var progress: CGFloat
    var onTap: (Value) -> Void
    /// View Properties
    @State private var tabTitleWidth: [Value: CGFloat] = [:]
    @State private var tabLocation: [Value: CGRect] = [:]
    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.title) { tab in
                let index = CGFloat(tabs.firstIndex(of: tab) ?? 0)
                let tabProgress = min(abs(cappedProgress - index), 1)

                if tab != tabs.first {
                    Spacer(minLength: 0)
                        .frame(height: 30)
                        .contentShape(.rect)
                        .onTapGesture {
                            onTap(tab)
                        }
                }

                if let tableWidth = tabTitleWidth[tab] {
                    HStack(spacing: 0) {
                        ZStack {
                            Image(systemName: tab.symbolImage)
                                .foregroundStyle(.gray)
                                .opacity(tabProgress)

                            Image(systemName: tab.symbolImage)
                                .foregroundStyle(.primary)
                                .opacity(1 - tabProgress)
                        }
                        .font(.system(size: 17, weight: .medium))
                        .frame(width: 25, height: 30, alignment: .leading)
                        .onGeometryChange(for: CGRect.self) { geometry in
                            geometry.frame(in: .named("CONTAINER"))
                        } action: { newValue in
                            var newRect = newValue
                            newRect.size.width = newValue.width + tableWidth
                            tabLocation[tab] = newRect
                        }

                        Text(tab.title)
                            .font(.system(size: 16, weight: .semibold))
                            .opacity(1 - tabProgress)
                            .fixedSize(horizontal: true, vertical: true)
                            .frame(
                                width: tableWidth * (1 - tabProgress),
                                alignment: .trailing
                            )
                            .lineLimit(1)
                            .mask {
                                Rectangle()
                                    .blur(radius: 5 * min(tabProgress * 5, 1))
                                    .padding(-2)
                            }
                    }
                    .contentShape(.rect)
                    .onTapGesture {
                        onTap(tab)
                    }
                }

                if tab != tabs.last {
                    Spacer(minLength: 0)
                        .frame(height: 30)
                        .contentShape(.rect)
                        .onTapGesture {
                            onTap(tab)
                        }
                }
            }
        }
        .coordinateSpace(.named("CONTAINER"))
        .padding(.bottom, 6)
        .overlay(alignment: .bottomLeading) {
            /// Resizing indicator
            if tabLocation.count == tabs.count {
                let extraWidth: CGFloat = 15
                let inputRange = tabs.indices.compactMap { CGFloat($0) }
                let outputSizeRange = tabs.compactMap {
                    (tabLocation[$0]?.size.width ?? 0) + extraWidth
                }
                let outputLocationRange = tabs.compactMap {
                    (tabLocation[$0]?.minX ?? 0) - (extraWidth / 2)
                }

                let indicatorWidth = cappedProgress
                    .interpolate(inputRange: inputRange, outputRange: outputSizeRange)
                let indicatorOffset = cappedProgress
                    .interpolate(inputRange: inputRange, outputRange: outputLocationRange)

                Rectangle()
                    .fill(.primary)
                    .frame(width: indicatorWidth, height: 2)
                    .offset(x: indicatorOffset)
            }
        }
        .onAppear {
            /// calculating title width
            for tab in tabs {
                let width = NSString(string: tab.title).size(withAttributes: [
                    .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
                ]).width
                tabTitleWidth[tab] = width
            }
        }
    }

    private var cappedProgress: CGFloat {
        max(min(progress, CGFloat(tabs.count - 1)), 0)
    }

    private var tabs: [Value] {
        Array(Value.allCases)
    }
}

#Preview {
    TextExpandableTabBarDemo()
}
