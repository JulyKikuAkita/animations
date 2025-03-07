//
//  AsyncImageViewer.swift
//  animation
//
//  iOS 18+ API with AsyncImage to parse image from url
//

import SwiftUI

struct AsyncImageViewer<Content: View, Overlay: View>: View {
    var config = AsyncImageViewerConfig()
    @ViewBuilder var content: Content
    @ViewBuilder var overlay: Overlay
    /// update to the main view
    var updates: (Bool, AnyHashable?) -> () = { _, _ in }
    /// View Properties
    @State private var isPresented: Bool = false
    @State private var activeTabID: Subview.ID?
    @State private var transitionSource: Int = 0
    @Namespace private var animation

    var body: some View {
        Group(subviews: content) { collection in
            /// iOS 18 subviews api to retrieve SubView collection from the given view content
            LazyVGrid(columns: Array(repeating: GridItem(spacing: config.spacing), count: 2), spacing: config.spacing) {
                /// Display the first 4 images only, and the remaining showing a plus sign and count (e.g., +2)
                let remainingCount = max(collection.count - 4, 0)
                ForEach(collection.prefix(4)) { item in
                    let index = collection.index(item.id)
                    GeometryReader {
                        let size = $0.size

                        item
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size.width, height: size.height)
                            .clipShape(.rect(cornerRadius: config.cornerRadius))

                        if collection.prefix(4).last?.id == item.id && remainingCount > 0 {
                            RoundedRectangle(cornerRadius: config.cornerRadius)
                                .fill(.black.opacity(0.35))
                                .overlay {
                                    Text("+\(remainingCount)")
                                        .font(.largeTitle)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.white)
                                }
                        }
                    }
                    .frame(height: config.height)
                    .frame(maxWidth: .infinity)
                    .onTapGesture {
                        /// For opening the selected image in the detail tab view
                        activeTabID = item.id
                        /// For opening navigation detail view
                        isPresented = true
                        /// For Zoom transition
                        transitionSource = index
                    }
                    .matchedTransitionSource(id: index, in: animation) { config in
                        config
                            .clipShape(.rect(cornerRadius: self.config.cornerRadius))
                    }
                }
            }
            .navigationDestination(isPresented: $isPresented) {
                TabView(selection: $activeTabID) {
                    ForEach(collection) { item in
                        item
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .tag(item.id)
                    }
                }
                .tabViewStyle(.page)
                .background {
                    Rectangle()
                        .fill(.black)
                        .ignoresSafeArea()
                }
                .overlay {
                    overlay
                }
                .navigationTransition(.zoom(sourceID: transitionSource, in: animation))
                .toolbarVisibility(.hidden, for: .navigationBar)
            }
            /// update transitionSource when tab item updated
            /// pin to index 3 to make sure match transition - zoom transition animation effect works for image not in display (index > 3), aka indexes > 3 will always have a transition id of 3
            .onChange(of: activeTabID) { oldValue, newValue in
                transitionSource = min(collection.index(newValue), 3)
                sendUpdate(collection, id: newValue)
            }
            .onChange(of: isPresented) { oldValue, newValue in
                sendUpdate(collection, id: activeTabID)
            }
        }
    }

    private func sendUpdate(_ collection: SubviewsCollection, id: Subview.ID?) {
        if let viewID = collection.first(where: { $0.id == id})?.containerValues.activeViewID {
            updates(isPresented, viewID)
        }
    }
}

struct AsyncImageViewerConfig {
    var height: CGFloat = 150
    var cornerRadius: CGFloat = 15
    var spacing: CGFloat = 10
}


fileprivate extension SubviewsCollection {
    func index(_ id: SubviewsCollection.Element.ID?) -> Int {
        firstIndex(where: { $0.id == id }) ?? 0
    }
}

/// To retrieve the current active ID, we can utilize container values to pass the ID to the view and the extract it from the subview
 extension ContainerValues {
    @Entry var activeViewID: AnyHashable?
}

#Preview {
    AsyncImageViewerViewDemo()
}
