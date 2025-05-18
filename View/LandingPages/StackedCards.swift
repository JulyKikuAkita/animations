//
//  StackedCards.swift
//  animation
// Demo apple stack notifications view

import SwiftUI

struct StackedCards<Content: View, Data: RandomAccessCollection>: View where Data.Element: Identifiable {
    var items: Data
    var stackedDisplayCount: Int = 2
    ///  number of extra cards needed to
    /// get the opacity effect in addition to the main card
    var opacityDisplayCount: Int = 2
    var spacing: CGFloat = 5
    var itemHeight: CGFloat
    @ViewBuilder var content: (Data.Element) -> Content

    var body: some View {
        GeometryReader {
            let size = $0.size
            let topPadding: CGFloat = size.height - itemHeight

            ScrollView(.vertical) {
                VStack(spacing: spacing) {
                    ForEach(items) { item in
                        content(item)
                            .frame(height: itemHeight)
                            .visualEffect { content, geometryProxy in
                                content
                                    .opacity(opacity(geometryProxy))
                                    .scaleEffect(scale(geometryProxy), anchor: .bottom)
                                    .offset(y: offset(geometryProxy))
                            }
                            .zIndex(zIndex(item))
                    }
                }
                .scrollTargetLayout()
                .overlay(alignment: .top) {
                    headerView(topPadding)
                }
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
            .safeAreaPadding(.top, topPadding)
            /// add padding directly to scrollContent rather than scrollView
            /// (if using standard padding) and thus allowing to scroll the stack all the way up
        }
    }

    func zIndex(_ item: Data.Element) -> Double {
        if let index = items.firstIndex(where: { $0.id == item.id }) as? Int {
            return Double(items.count) - Double(index)
        }
        return 0
    }

    /// Offset & scaling values for each item to make it look like a stack
    nonisolated func offset(_ proxy: GeometryProxy) -> CGFloat {
        let minY = proxy.frame(in: .scrollView(axis: .vertical)).minY
        let progress = minY / itemHeight
        let maxOffset = CGFloat(stackedDisplayCount) * offsetForEachItem
        let offset = max(min(progress * offsetForEachItem, maxOffset), 0)

        return minY < 0 ? 0 : -minY + offset
    }

    nonisolated func scale(_ proxy: GeometryProxy) -> CGFloat {
        let minY = proxy.frame(in: .scrollView(axis: .vertical)).minY
        let progress = minY / itemHeight
        let maxScale = CGFloat(stackedDisplayCount) * scaleForEachItem
        let scale = max(min(progress * scaleForEachItem, maxScale), 0)

        return 1 - scale
    }

    nonisolated func opacity(_ proxy: GeometryProxy) -> CGFloat {
        let minY = proxy.frame(in: .scrollView(axis: .vertical)).minY
        let progress = minY / itemHeight
        let opacityForItem = 1 / CGFloat(opacityDisplayCount + 1)

        let maxOpacity = CGFloat(opacityForItem) * CGFloat(opacityDisplayCount + 1)
        let opacity = max(min(progress * opacityForItem, maxOpacity), 0)

        return progress < CGFloat(opacityDisplayCount + 1) ? 1 - opacity : 0
    }

    nonisolated var offsetForEachItem: CGFloat {
        8
    }

    nonisolated var scaleForEachItem: CGFloat {
        0.08
    }

    func headerView(_ topPadding: CGFloat) -> some View {
        VStack(spacing: 0) {
            Text(Date.now.formatted(date: .complete, time: .omitted))
                .font(.title3.bold())

            Text("1:11")
                .font(.system(size: 100, weight: .bold, design: .rounded))
                .padding(.top, -15)
        }
        .foregroundStyle(.white)
        .visualEffect { content, geometryProxy in
            content.offset(y: headerViewOffset(geometryProxy, topPadding))
        }
    }

    /// position header view on top until stacked card getting close to it then scroll with the cards
    nonisolated func headerViewOffset(_ proxy: GeometryProxy, _ topPadding: CGFloat) -> CGFloat {
        let minY = proxy.frame(in: .scrollView(axis: .vertical)).minY
        let viewSize = proxy.size.height - itemHeight

        return -minY > (topPadding - viewSize) ? -viewSize : -minY - topPadding
    }
}

#Preview {
    StackedScrollView()
        .preferredColorScheme(.dark)
}
