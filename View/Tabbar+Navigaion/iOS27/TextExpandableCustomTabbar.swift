//
//  TextExpandableCustomTabbar.swift
//  animation
//
//  Created on 7/29/26.

// Learning notes (see XStyleTabBar below for detail):
// - Continuous progress, not discrete index: `onScrollGeometryChange` derives a fractional
//   `scrollProgress` from contentOffset/containerSize, so the indicator and label collapse
//   animate smoothly mid-swipe instead of snapping at page boundaries.
// - One-way state sync to avoid feedback loops: scrolling drives `scrollProgress` -> tab bar;
//   tapping a tab drives `scrollPosition.scrollTo` -> scroll view. Each direction only ever
//   writes the other's input, never both at once.
// - `onGeometryChange` in a shared `.coordinateSpace(.named("CONTAINER"))` captures each tab's
//   frame after layout, which `interpolate(inputRange:outputRange:)` (see Interpolation.swift)
//   then uses to slide/resize the underline indicator between arbitrary tab widths.
// - `tabProgress = min(abs(cappedProgress - index), 1)` is a per-tab "distance from selected"
//   value, reused to drive the icon crossfade, label width collapse, and blur mask together.

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

/// Learning note — progress-driven tab bar whose label width collapses to an icon as it moves
/// away from the selected tab, with a sliding underline sized to each tab's full (icon + text) width.
/// - `progress`: continuous 0...(tabCount-1) value from the paired scroll view, not a discrete index —
///   this is what makes the collapse/underline animate smoothly mid-swipe.
/// - `tabLocation`: per-tab frame captured in the `"CONTAINER"` coordinate space, width-adjusted to
///   include the full (untruncated) title so the underline reflects the tab's resting size, not its
///   currently-collapsing size.
/// - The leading/trailing `Spacer` around each tab extends its tap target into the inter-tab gap,
///   since the label itself shrinks but the tap area shouldn't.
struct XStyleTabBar<Value: XStyleTabItem>: View {
    var progress: CGFloat
    var onTap: (Value) -> Void
    /// View Properties
    @State private var titleWidth: [Value: CGFloat] = [:]
    @State private var tabLocation: [Value: CGRect] = [:]
    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.title) { tab in
                let index = CGFloat(tabs.firstIndex(of: tab) ?? 0)

                /// Per-tab collapse progress driving the icon+text expand/collapse effect.
                ///
                /// A continuous 0...1 "distance from selected" value, not a boolean, so the
                /// collapse tracks smoothly mid-swipe instead of snapping at tab boundaries.
                /// It fans out into three effects on the label below:
                /// - Text width: `tabTitleWidth * (1 - tabProgress)` shrinks the label from its
                ///   cached full-text width down to zero.
                /// - Text opacity: `1 - tabProgress` fades the label in sync with the shrink.
                /// - Blur mask: ramps with `tabProgress` so the narrowing edge reads as a
                ///   dissolve rather than a hard clip.
                ///
                /// The icon stays a fixed size and only crossfades tint (gray ↔ primary) via two
                /// overlaid images at `opacity(tabProgress)` / `opacity(1 - tabProgress)`, which
                /// also keeps its frame stable for the underline's geometry capture.
                let tabProgress = min(abs(cappedProgress - index), 1)

                /// maintain layout as
                /// [A content] [A-trailing Spacer] [B-leading Spacer] [B content] [B-trailing Spacer] [C-leading Spacer] [C content]
                if tab != tabs.first {
                    Spacer(minLength: 0)
                        .frame(height: 30)
                        .contentShape(.rect)
                        .onTapGesture {
                            onTap(tab)
                        }
                }

                if let tabTitleWidth = titleWidth[tab] {
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
                        // Anchor on the icon, not the icon+text HStack: the HStack's width shrinks
                        // every frame during scroll (Text narrows with tabProgress), so its geometry
                        // is unstable. The icon's frame is fixed, giving a stable minX for the tab's
                        // left edge; add the cached title width to get its full resting width.
                        .onGeometryChange(for: CGRect.self) { geometry in
                            geometry.frame(in: .named("CONTAINER"))
                        } action: { newValue in
                            var newRect = newValue
                            newRect.size.width = newValue.width + tabTitleWidth
                            tabLocation[tab] = newRect
                        }

                        Text(tab.title)
                            .font(.system(size: 16, weight: .semibold))
                            .opacity(1 - tabProgress)
                            .fixedSize(horizontal: true, vertical: true)
                            .frame(
                                width: tabTitleWidth * (1 - tabProgress),
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
            // Wait for every tab's frame to be measured before drawing, otherwise the indicator
            // briefly renders at a wrong size/position off the first, partially-populated frames.
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
                titleWidth[tab] = width
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
