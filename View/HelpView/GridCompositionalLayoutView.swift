//
//  GridCompositionalLayoutView.swift
//  animation

import SwiftUI

struct GridCompositionalLayoutDemoView: View {
    @State private var count: Int = 3
    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                LazyVStack(spacing: 6) {
                    PickerView()
                        .padding(.bottom, 10)

                    GridCompositionalLayoutView(count: count) {
                        ForEach(1 ... 50, id: \.self) { index in
                            Rectangle()
                                .fill(.black.gradient)
                                .overlay {
                                    Text("\(index)")
                                        .font(.largeTitle.bold())
                                        .foregroundStyle(.white)
                                }
                        }
                    }
                    .animation(.bouncy, value: count)
                }
                .padding(15)
            }
            .navigationTitle("Compositional Grid")
        }
    }

    @ViewBuilder
    func PickerView() -> some View {
        Picker("", selection: $count) {
            ForEach(1 ... 4, id: \.self) {
                Text("\($0) grid")
                    .tag($0)
            }
        }
        .pickerStyle(.segmented)
    }
}

struct GridCompositionalLayoutView<Content: View>: View {
    var count: Int = 3
    var spacing: CGFloat = 6
    @ViewBuilder var content: Content
    @Namespace private var gridAnimation
    var body: some View {
        Group(subviews: content) { collection in
            let chunked = collection.chunked(count)

            ForEach(chunked) { chunk in
                switch chunk.layoutID {
                case 0: OneGridLayout(chunk.collection)
                case 1: TwoGridLayout(chunk.collection)
                case 2: ThreeGridLayout(chunk.collection)
                default: FourGridLayout(chunk.collection)
                }
            }
        }
    }

    @ViewBuilder
    func OneGridLayout(_ collection: [SubviewsCollection.Element]) -> some View {
        GeometryReader {
            let width = $0.size.width - spacing

            HStack(spacing: spacing) {
                if let first = collection.first {
                    first
                        .matchedGeometryEffect(id: first.id, in: gridAnimation)
                }

                VStack(spacing: spacing) {
                    ForEach(collection.dropFirst()) {
                        $0
                            .matchedGeometryEffect(id: $0.id, in: gridAnimation)
                            .frame(width: width * 0.33)
                    }
                }
            }
        }
        .frame(height: 200)
    }

    @ViewBuilder
    func TwoGridLayout(_ collection: [SubviewsCollection.Element]) -> some View {
        HStack(spacing: spacing) {
            ForEach(collection) {
                $0
                    .matchedGeometryEffect(id: $0.id, in: gridAnimation)
            }
        }
        .frame(height: 100)
    }

    @ViewBuilder
    func ThreeGridLayout(_ collection: [SubviewsCollection.Element]) -> some View {
        GeometryReader {
            let width = $0.size.width - spacing

            HStack(spacing: spacing) {
                if let first = collection.first {
                    first
                        .matchedGeometryEffect(id: first.id, in: gridAnimation)
                        .frame(width: collection.count == 1 ? width : width * 0.33)
                }
                VStack(spacing: spacing) {
                    ForEach(collection.dropFirst()) {
                        $0
                            .matchedGeometryEffect(id: $0.id, in: gridAnimation)
                    }
                }
            }
        }
        .frame(height: 200)
    }

    @ViewBuilder
    func FourGridLayout(_ collection: [SubviewsCollection.Element]) -> some View {
        HStack(spacing: spacing) {
            ForEach(collection) {
                $0
                    .matchedGeometryEffect(id: $0.id, in: gridAnimation)
            }
        }
        .frame(height: 230)
    }
}

private extension SubviewsCollection {
    func chunked(_ size: Int) -> [ChunkedCollection] {
        stride(from: 0, to: count, by: size).map {
            let collection = Array(self[$0 ..< Swift.min($0 + size, count)])
            let layoutID = ($0 / size) % 4
            print(layoutID)
            return .init(layoutID: layoutID, collection: collection)
        }
    }

    struct ChunkedCollection: Identifiable {
        var id: UUID = .init()
        var layoutID: Int
        var collection: [SubviewsCollection.Element]
    }
}

#Preview {
    GridCompositionalLayoutDemoView()
}
