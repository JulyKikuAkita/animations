//
//  PhotoGridViewIos26+TransitionEffect.swift
//  animation
//
//  Created on 3/4/26.
// Simulate Apple Photo app iOS26 transition animation

import SwiftUI

extension PhotoItem: PhotoProtocol {}

struct PhotoGridIOS26TransitionDemoView: View {
    var body: some View {
        NavigationStack {
            PhotoGridView(data: samplePhotoItems) { item in
                imageView(item)
            } detail: { item, _, _ in
                imageView(item)
            } overlay: { _, _, _, _ in

            } onSelectionChanged: { item in
                if let item {}
            }.navigationTitle("Library")
        }
    }

    func imageView(_ item: PhotoItem) -> some View {
        Rectangle()
            .foregroundStyle(.clear)
            .overlay {
                if let image = item.image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
            }
    }
}

protocol PhotoProtocol: Hashable {
    var id: String { get }
}

private struct PhotoHeroEffectConfig<Element: PhotoProtocol> {
    var selectedItem: Element?
    var sourceLocation: CGRect = .zero
    var sourceScrollPosition: ScrollPosition = .init()
    var showFullScreenCover: Bool = false
}

struct PhotoGridView<Data: RandomAccessCollection, GridItem: View, Detail: View, Overlay: View>: View where Data.Element: PhotoProtocol {
    var spacing: CGFloat = 5
    var gridCount: Int = 3
    var gridItemHeight: CGFloat = 120
    var data: Data

    @ViewBuilder var gridItem: (Data.Element) -> GridItem
    @ViewBuilder var detail: (Data.Element, Bool, () -> Void) -> Detail
    @ViewBuilder var overlay: (Data.Element, Bool, CGSize, () -> Void) -> Overlay
    var onSelectionChanged: (Data.Element?) -> Void = { _ in }
    /// View Properties
    @State private var config: PhotoHeroEffectConfig<Data.Element> = .init()

    var body: some View {
        let gridItems = Array(repeating: SwiftUI.GridItem(spacing: spacing), count: gridCount)

        ScrollView(.vertical) {
            LazyVGrid(columns: gridItems, spacing: spacing) {
                ForEach(data, id: \.id) { item in
                    Rectangle()
                        .foregroundStyle(.clear)
                        .overlay {
                            GeometryReader {
                                let rect = $0.frame(in: .global)
                                let isUpdated = config.selectedItem == item && config.sourceLocation != rect

                                gridItem(item)
                                    /// hiding the source view when enable hero effect animation
                                    .opacity(config.selectedItem == item ? 0 : 1)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .contentShape(.rect)
                                    .onTapGesture {
                                        /// Storing info and opening full screen hero view
                                        config.selectedItem = item
                                        config.sourceLocation = rect
                                        /// Opening full screen cover without animation
                                        withoutAnimation {
                                            config.showFullScreenCover = true
                                        }
                                    }
                                    .onChange(of: isUpdated) { _, _ in
                                        config.sourceLocation = rect
                                    }
                            }
                        }
                        .frame(height: gridItemHeight)
                        .clipped()
                        .contentShape(.rect)
                }
            }
            .scrollTargetLayout()
        }
        .scrollPosition($config.sourceScrollPosition)
        .fullScreenCover(isPresented: $config.showFullScreenCover) {
            config.selectedItem = nil
        } content: {}
        /// publish selected item change along with the source scroll view position when updating in enlarged view
        .onChange(of: config.selectedItem) { oldValue, newValue in
            if let newValue, oldValue != nil {
                config.sourceScrollPosition.scrollTo(id: newValue.id)
            }
            onSelectionChanged(newValue)
        }
    }
}

private extension View {
    func withoutAnimation(_ result: @escaping () -> Void) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            result()
        }
    }
}
