//
//  ScrollHeroEffect.swift
//  animation
//
//  Created on 1/24/26.
import SwiftUI

struct ScrollHeroEffectConfig {
    var expandDetailView: Bool = false
    var sourceIndex: Int?
    var dismissIndex: Int?

    /// Customization Properties
    var spacing: CGFloat = 10
    var destinationCornerRadius: CGFloat = 30
}

struct SourceHeroEffectScrollView<Content: View, Data: RandomAccessCollection>: View where Data.Element: Identifiable {
    @Binding var config: ScrollHeroEffectConfig
    var nameSpace: Namespace.ID
    var cardWidth: CGFloat = 160
    var data: Data
    var id: KeyPath<Data.Element, UUID>
    @ViewBuilder var content: (Data.Element) -> Content
    var body: some View {
        GeometryReader {
            let size = $0.size

            ScrollView(.horizontal) {
                HStack(spacing: config.spacing) {
                    ForEach(data, id: id) { item in
                        ZStack {
                            if !config.expandDetailView {
                                content(item)
                                    .background {
                                        /// expanding effect
                                        Rectangle()
                                            .foregroundStyle(.clear)
                                            .matchedGeometryEffect(id: item.id, in: nameSpace)
                                    }
                            }
                        }
                        .frame(width: cardWidth, height: size.height)
                        .contentShape(.rect)
                    }
                }
            }
            .scrollClipDisabled()
        }
        /// enable when no details is displaying
        .allowsHitTesting(config.sourceIndex == nil)
    }
}

struct DetailHeroEffectScrollView<Content: View, Data: RandomAccessCollection>: View where Data.Element: Identifiable {
    @Binding var config: ScrollHeroEffectConfig
    var nameSpace: Namespace.ID
    var data: Data
    var id: KeyPath<Data.Element, UUID>
    @ViewBuilder var content: (Data.Element) -> Content
    var body: some View {
        GeometryReader {
            let size = $0.size

            if let sourceIndex = config.sourceIndex, config.expandDetailView {
                /// setup initial anchor
                let anchorX: CGFloat = ((CGFloat(sourceIndex) * size.width) / (CGFloat(data.count - 1) * size.width))

                ScrollView(.horizontal) {
                    HStack(spacing: config.spacing) {
                        ForEach(data, id: id) { item in
                            Rectangle()
                                .foregroundStyle(.clear)
                                .overlay {
                                    GeometryReader {
                                        let innerSize = $0.size
                                        content(item)
                                            .frame(
                                                width: innerSize.width,
                                                height: innerSize.height,
                                                alignment: .top
                                            )
                                            .background(.green)
                                            .clipShape(.rect(cornerRadius: config.destinationCornerRadius))
                                    }
                                }
                                .matchedGeometryEffect(id: item.id, in: nameSpace)
                                .frame(width: size.width, height: size.height)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned(limitBehavior: .alwaysByFew))
                .defaultScrollAnchor(.init(x: anchorX, y: 0.5), for: .initialOffset)
                .scrollClipDisabled()
                .onDisappear {
                    /// Reset scroll properties
                    config = .init()
                }
            }
        }
        /// enable when details is displaying
        .allowsHitTesting(config.sourceIndex != nil)
    }
}

#Preview {
    BookContentView()
}
