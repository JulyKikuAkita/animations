//
//  BookContentView.swift
//  animation
//
//  Created on 1/24/26.

import SwiftUI

struct BookContentView: View {
    @State private var config: ScrollHeroEffectConfig = .init()
    @State private var config1: ScrollHeroEffectConfig = .init()
    @Namespace private var namespace

    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 15) {
                    Section("Scenic") {
                        SourceHeroEffectScrollView(config: $config, nameSpace: namespace, data: scenic, id: \.id) { item in
                            imageView(item)
                                .onTapGesture {
                                    if let index = scenic.firstIndex(where: { $0.id == item.id }) {
                                        withAnimation(.interpolatingSpring(duration: 1)) {
                                            config.sourceIndex = index
                                            config.expandDetailView = true
                                        }
                                    }
                                }
                                .transition(.offset(x: 1))
                        }
                        .frame(height: 220)
                    }
                    .font(.title2.bold())

                    Section("Illustrations") {
                        SourceHeroEffectScrollView(config: $config1, nameSpace: namespace, data: illustrations, id: \.id) { item in
                            imageView(item)
                                .onTapGesture {
                                    if let index = illustrations.firstIndex(where: { $0.id == item.id }) {
                                        withAnimation(.interpolatingSpring(duration: 1)) {
                                            config1.sourceIndex = index
                                            config1.expandDetailView = true
                                        }
                                    }
                                }
                                .transition(.offset(x: 1))
                        }
                        .frame(height: 220)
                    }
                    .font(.title2.bold())
                }
            }
            .safeAreaPadding(.horizontal, 15)
            .navigationTitle("Photos")
            .toolbarTitleDisplayMode(.inlineLarge)
        }
        .overlay {
            ZStack {
                DetailHeroEffectScrollView(
                    config: $config,
                    nameSpace: namespace,
                    data: scenic,
                    id: \.id
                ) { item, progress in
                    DetailItemView(config: $config, photo: item, progress: progress, namespace: namespace)
                }

                DetailHeroEffectScrollView(
                    config: $config1,
                    nameSpace: namespace,
                    data: illustrations,
                    id: \.id
                ) { item, progress in
                    DetailItemView(config: $config1, photo: item, progress: progress, namespace: namespace)
                }
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

#Preview {
    BookContentView()
}
