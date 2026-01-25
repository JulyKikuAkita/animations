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

    /// View Properties
    @State private var scrollPosition: ScrollPosition = .init()

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
            .scrollPosition($scrollPosition)
            .scrollClipDisabled()
            .onChange(of: config.dismissIndex) { _, newValue in
                guard let index = newValue else { return }
                /// Updating scroll position
                let contentWidth = CGFloat(index) * cardWidth
                let spacing = config.spacing * CGFloat(index)
                scrollPosition.scrollTo(x: contentWidth + spacing)
            }
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
    @ViewBuilder var content: (Data.Element, CGFloat) -> Content
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
                                        let progress = max(min(innerSize.width / size.width, 1), 0)

                                        content(item, progress)
                                            .frame(
                                                width: size.width,
                                                height: size.height
                                            )
                                            .frame(
                                                width: innerSize.width,
                                                height: innerSize.height,
                                                alignment: .top
                                            )
                                            .background(.background)
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
                .onScrollPhaseChange { oldPhase, newPhase, context in
                    guard oldPhase != .idle, newPhase != .idle else { return }
                    let geometry = context.geometry
                    let offset = geometry.contentOffset.x + geometry.contentInsets.leading
                    let index = Int((offset / size.width).rounded())

                    guard config.sourceIndex != index else { return }
                    config.dismissIndex = index
                }
                .onDisappear {
                    /// Reset scroll properties
                    config = .init()
                }
            }
        }
        .background {
            if config.expandDetailView {
                ZStack {
                    Rectangle()
                        .fill(.ultraThinMaterial)

                    Rectangle()
                        .fill(.black.opacity(0.3))
                }
                .ignoresSafeArea()
            }
        }
        /// enable when details is displaying
        .allowsHitTesting(config.sourceIndex != nil)
    }
}

#Preview {
    BookContentView()
}
