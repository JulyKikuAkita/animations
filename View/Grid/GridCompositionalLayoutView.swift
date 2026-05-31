//
//  GridCompositionalLayoutView.swift
//  animation
//
//  Standalone demo (not wired into the app's demo browser; preview-only).
//  iOS 17.1+ — `Group(subviews:)` is the gating API.
//
//  Learning point
//  ──────────────
//  Dynamic grid that morphs between 1, 2, 3, 4-column layouts via
//  a segmented picker. As the column count changes, EVERY cell
//  animates from its old position to its new one via
//  `matchedGeometryEffect` in a shared `Namespace`. Result: cells
//  appear to slide between layouts rather than re-laying out
//  abruptly.
//
//  Why `Group(subviews:)` is load-bearing
//  ──────────────────────────────────────
//  The reusable `GridCompositionalLayoutView<Content>` accepts a
//  `@ViewBuilder` closure and uses iOS 17.1+ `Group(subviews:)` to
//  extract the children as a `SubviewsCollection`. From there, a
//  local `ChunkedCollection` extension chunks the subviews into
//  rows of N. This lets callers write a flat `ForEach { ... }` and
//  have the helper handle the row-splitting math.
//
//  The morph mechanic
//  ──────────────────
//  Each subview has a stable `id` (chunk index + position-in-chunk).
//  When the column count changes, SwiftUI sees the SAME ids appear
//  at NEW positions in the layout. Combined with
//  `.matchedGeometryEffect(id: ..., in: namespace)` and a `.bouncy`
//  animation, SwiftUI interpolates each cell's frame from old → new
//  for free.
//
//  Key APIs
//  ────────
//  • `Group(subviews: content) { collection in ... }` — iOS 17.1+
//    SubViews API. The whole demo hinges on this.
//  • `matchedGeometryEffect(id:in:)` — drives the per-cell morph.
//  • `Namespace` — shared between the picker target and the chunk
//    layout so ids match across layout changes.
//  • `ChunkedCollection<C>` — file-local extension on
//    `SubviewsCollection` that yields N-item slices. Could be lifted
//    if reused.
//  • `.bouncy` — the unifying animation curve; `bouncy` reads as
//    "physical" without overshooting too much.
//
//  How to apply
//  ────────────
//  Use whenever a grid has a USER-CONTROLLED column count or needs
//  to adapt to size-class changes. The chunking helper is
//  generalisable — copy it into any project that wants
//  declarative N-up grid math.
//
//  See also
//  ────────
//  • GridView.swift — fixed 3-column grid; this file's "static
//    counterpart."
//  • View/Carousel/CardCarouselView.swift — different reduction-
//    on-scroll trick; complementary visual technique.
//
import SwiftUI

struct GridCompositionalLayoutDemoView: View {
    @State private var count: Int = 3
    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                LazyVStack(spacing: 6) {
                    pickerView()
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

    func pickerView() -> some View {
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
                case 0: oneGridLayout(chunk.collection)
                case 1: twoGridLayout(chunk.collection)
                case 2: threeGridLayout(chunk.collection)
                default: fourGridLayout(chunk.collection)
                }
            }
        }
    }

    func oneGridLayout(_ collection: [SubviewsCollection.Element]) -> some View {
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

    func twoGridLayout(_ collection: [SubviewsCollection.Element]) -> some View {
        HStack(spacing: spacing) {
            ForEach(collection) {
                $0
                    .matchedGeometryEffect(id: $0.id, in: gridAnimation)
            }
        }
        .frame(height: 100)
    }

    func threeGridLayout(_ collection: [SubviewsCollection.Element]) -> some View {
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

    func fourGridLayout(_ collection: [SubviewsCollection.Element]) -> some View {
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
