//
//  CustomList+iOS26.swift
//  animation
//
//  Created on 9/11/25.
// iOS 26

import SwiftUI

struct CustomListiOS26DemoView: View {
    @State private var menuCards: [MenuCard] = [
        .init(title: "Order Again"),
        .init(title: "Picked For You"),
        .init(title: "Starters"),
        .init(title: "French"),
    ]
    @State private var currentMenuTitle: String?
    var body: some View {
        ScrollViewReader { reader in
            CustomList { _ in
                navBarView()

            } topContent: { progress, safeAreaTop in
                heroImage(progress, safeAreaTop)

            } header: { progress in
                headerView(progress)

            } content: {
                ForEach(menuCards) { card in
                    Section {
                        ForEach(card.items) { _ in
                            DummyCardStyleView()
                                .customListRow(top: 5, bottom: 5)
                        }
                    } header: {
                        Text(card.title)
                            .font(.title2.bold())
                            .padding(15)
                            .onGeometryChange(for: CGFloat.self) {
                                $0.frame(in: .global).minY
                            } action: { newValue in
                                updateCurrentMenutTitle(card: card, offset: newValue)
                            }
                            .id(card.id)
                            .customListRow()
                    }
                }
            }
            .onScrollPhaseChange { _, newPhase, context in
                let offset = context.geometry.contentOffset.y + context.geometry.contentInsets.top
                if newPhase == .idle, offset > 0 {
                    guard let firstCardID = menuCards.first?.id else { return }

                    if offset < 250 {
                        if offset < 125 {
                            /// Reset to top
                            withAnimation(.easeInOut(duration: 0.2)) {
                                reader.scrollTo(firstCardID, anchor: .bottom)
                            }
                        } else {
                            /// Reset to header view
                            withAnimation(.easeInOut(duration: 0.2)) {
                                reader.scrollTo(firstCardID, anchor: .top)
                            }
                        }
                    }
                }
            }
        }
        .task {
            guard currentMenuTitle == nil else { return }
            currentMenuTitle = menuCards.first?.title
        }
    }

    func heroImage(_: CGFloat, _ safeAreaTop: CGFloat) -> some View {
        GeometryReader {
            let minY = $0.frame(in: .global).minY - safeAreaTop
            let size = $0.size
            let height = size.height + (minY > 0 ? minY : 0)

            Image(.fox)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size.width, height: height + safeAreaTop)
                .offset(y: minY > 0 ? -minY : 0)
                .offset(y: -safeAreaTop)
        }
        .frame(height: 250)
    }

    func headerView(_ progress: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Apple Foods")
                .font(.title2.bold())
                .frame(height: 35)
                .offset(x: min(progress * 1.1, 1) * 45)

            let opacity = max(0, 1 - (progress * 1.3))
            let currentMenuTitleOpacity = max(progress - 0.9, 0) * 10
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .font(.caption)

                Text("4.5 **(20K ratings)**")
                    .font(.callout)

                Image(systemName: "clock")
                    .font(.system(size: 15, weight: .semibold))
                    .padding(.leading, 10)

                Text("35-40 **Mins**")
                    .font(.callout)
            }
            .opacity(opacity)
            .overlay(alignment: .leading) {
                Text(currentMenuTitle ?? "")
                    .font(.system(size: 14))
                    .foregroundStyle(.gray)
                    .fontWeight(.medium)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: currentMenuTitle)
                    .offset(x: 45, y: -5)
                    .opacity(currentMenuTitleOpacity)
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            /// starts only after the progress goes beyond 0.8 and gives in a progress range between 0-1
            let backgroundProgress = max(progress - 0.8, 0) * 5
            Rectangle()
                .fill(.background)
                /// Increasing the background till the safe area top
                .padding(.top, backgroundProgress * -100)
                .shadow(color: .gray.opacity(backgroundProgress * 0.3), radius: 5, x: 0, y: 2)
        }
    }

    func navBarView() -> some View {
        HStack {
            Button {} label: {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(.primary, .background)
                    .shadow(radius: 2)
                    .frame(height: 35)
            }

            Spacer()

            Button {} label: {
                Image(systemName: "ellipsis.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(.primary, .background)
                    .shadow(radius: 2)
                    .frame(height: 35)
            }
        }
        .padding(.horizontal, 15)
        /// matching the top padding with the HEader's top padding
        .padding(.top, 10)
    }

    fileprivate func updateCurrentMenutTitle(card: MenuCard, offset: CGFloat) {
        if offset < 200 {
            if card.title != currentMenuTitle {
                currentMenuTitle = card.title
            }
        } else {
            /// Going back to previous section!
            if currentMenuTitle == card.title, card.id != menuCards.first?.id {
                /// Finding previous index
                if let currentIndex = menuCards.firstIndex(where: { $0.id == card.id }) {
                    let previousIndex = max(menuCards.index(before: currentIndex), 0)
                    currentMenuTitle = menuCards[previousIndex].title
                }
            }
        }
    }
}

extension View {
    func customListRow(top: CGFloat = 0, bottom: CGFloat = 0) -> some View {
        listRowInsets(.init(top: top, leading: 0, bottom: bottom, trailing: 0))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }
}

struct CustomList<NavBar: View, TopContent: View, Header: View, Content: View>: View {
    @ViewBuilder var navBar: (_ progress: CGFloat) -> NavBar
    @ViewBuilder var topContent: (_ progress: CGFloat, _ safeAreaTop: CGFloat) -> TopContent
    @ViewBuilder var header: (_ progress: CGFloat) -> Header
    @ViewBuilder var content: Content
    /// View Properties
    @State private var headerProgress: CGFloat = 0
    @State private var safeAreaTop: CGFloat = 0
    @State private var topContentHeight: CGFloat = 0
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        List {
            topContent(headerProgress, safeAreaTop)
                .onGeometryChange(for: CGFloat.self, of: {
                    $0.size.height
                }, action: { newValue in
                    topContentHeight = newValue
                })
                .customListRow() // this vm needs to be placed at the last line

            Section {
                content
            } header: {
                header(headerProgress)
                    .foregroundStyle(foregroundColor)
                    .onGeometryChange(for: CGFloat.self, of: {
                        topContentHeight == .zero ? 0 : $0.frame(in: .named("LISTVIEW")).minY
                    }, action: { newValue in
                        guard topContentHeight != .zero else { return }
                        let progress = (newValue - safeAreaTop) / topContentHeight
                        let cappedProgress = 1 - max(min(progress, 1), 0)
                        headerProgress = cappedProgress
                    })
                    .customListRow()
            }
        }
        .listStyle(.plain)
        .listRowSpacing(0)
        .listSectionSpacing(0)
        .overlay(alignment: .top) {
            navBar(headerProgress)
        }
        .coordinateSpace(.named("LISTVIEW"))
        .onGeometryChange(for: CGFloat.self) {
            $0.safeAreaInsets.top
        } action: { newValue in
            safeAreaTop = newValue
        }
    }

    var foregroundColor: Color {
        colorScheme == .dark ? .white : .black
    }
}

#Preview {
    CustomListiOS26DemoView()
}

private struct MenuCard: Identifiable {
    var id: String = UUID().uuidString
    var title: String
    var items: [MenuItem] = (1 ... 5).compactMap { _ in .init() }
}

private struct MenuItem: Identifiable {
    var id: String = UUID().uuidString
}
