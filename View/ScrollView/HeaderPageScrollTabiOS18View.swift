//
//  HeaderPageScrollTabiOS18View.swift
//  animation

import SwiftUI

struct HeaderPageScrollTabiOS18DemoView: View {
    var body: some View {
        HeaderPageScrollTabiOS18View(displaysSymbols: false) {
            Rectangle()
                .fill(.blue.gradient)
                .frame(height: 350)
        } labels: {
            PageLabel(title: "Posts", symbolImage: "square.grid.3x3.fill")
            PageLabel(title: "Reels", symbolImage: "photo.stack.fill")
            PageLabel(title: "Tagged", symbolImage: "person.square.rectangle")
        } pages: {
            /// assuming each is individual tab view
            Text("Posts")

            Text("Reels")

            Text("Tagged")
        }
    }
}

struct PageLabel {
    var title: String
    var symbolImage: String
}

@resultBuilder
struct PageLabelBuilder {
    static func buildBlock(_ components: PageLabel...) -> [PageLabel] {
        components.compactMap(\.self)
    }
}

struct HeaderPageScrollTabiOS18View<Header: View, Pages: View>: View {
    var displaysSymbols: Bool = false
    @ViewBuilder var header: Header
    /// labels: tab title or tab images
    @PageLabelBuilder var labels: [PageLabel]
    @ViewBuilder var pages: Pages

    /// View Properties
    @State private var activeTabText: String?
    @State private var headerHeight: CGFloat = 0

    var body: some View {
        GeometryReader {
            let size = $0.size

            ScrollView(.horizontal) {
                /// using hstack allowing us to maintain reference to other scrollviews for future updates
                HStack(spacing: 0) {
                    Group(subviews: pages) { collection in
                        if collection.count != labels.count {
                            Text("Textviews and labels does not match")
                                .frame(width: size.width, height: size.height)
                        } else {
                            ForEach(labels, id: \.title) { label in
                                pageScrollView(label: label, size: size, collection: collection)
                            }
                        }
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $activeTabText)
            .scrollIndicators(.hidden)
            .onAppear {
                guard activeTabText == nil else { return }
                activeTabText = labels.first?.title
            }
        }
    }

    func pageScrollView(label: PageLabel, size: CGSize, collection: SubviewsCollection) -> some View {
        let index = labels.firstIndex(where: { $0.title == label.title }) ?? 0
        return ScrollView(.vertical) {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                /// show header view for the active tab only
                ZStack {
                    if activeTabText == label.title {
                        header
                            .onGeometryChange(for: CGFloat.self) {
                                $0.size.height
                            } action: { newValue in
                                headerHeight = newValue
                            }
                            .transition(.identity)
                    } else {
                        Rectangle()
                            .foregroundStyle(.clear)
                            .frame(height: headerHeight)
                            .transition(.identity)
                    }
                }

                /// using pinned views to pin tab bar on the top
                Section {
                    collection[index]
                } header: {
                    customTabBar()
                }
            }
        }
        .frame(width: size.width, height: size.height)
    }

    func customTabBar() -> some View {
        HStack(spacing: 0) {
            ForEach(labels, id: \.title) { label in
                Group {
                    if displaysSymbols {
                        Image(systemName: label.symbolImage)
                    } else {
                        Text(label.title)
                    }
                }
                .frame(maxWidth: .infinity)
                .foregroundStyle(activeTabText == label.title ? Color.primary : .gray)
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        activeTabText = label.title
                    }
                }
            }
        }
        .frame(height: 40)
    }
}

#Preview {
    HeaderPageScrollTabiOS18DemoView()
}
