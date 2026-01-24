//
//  BookContentView.swift
//  animation
//
//  Created on 1/24/26.

import SwiftUI

struct BookContentView: View {
    @State private var config: ScrollHeroEffectConfig = .init()
    @Namespace private var namespace

    var body: some View {
        VStack {
            SourceHeroEffectScrollView(config: $config, nameSpace: namespace, data: scenic, id: \.id) { item in
                imageView(item)
                    .onTapGesture {
                        if let index = scenic.firstIndex(where: { $0.id == item.id }) {
                            withAnimation(.interpolatingSpring(duration: 3)) {
                                config.sourceIndex = index
                                config.expandDetailView = true
                            }
                        }
                    }
                    .transition(.offset(x: 1))
            }
            .frame(height: 220)
        }
        .safeAreaPadding(.horizontal, 15)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay {
            DetailHeroEffectScrollView(config: $config, nameSpace: namespace, data: scenic, id: \.id) { item in
                DetailItemView(config: $config, photo: item, namespace: namespace)
            }
            .safeAreaPadding(.horizontal, 20)
        }
    }

    func imageView(_ item: Photo) -> some View {
        Rectangle()
            .foregroundStyle(.clear)
            .overlay {
                Image(item.assetName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
            .clipShape(.rect(cornerRadius: 10))
            .matchedGeometryEffect(id: item.imageID, in: namespace)
    }
}
