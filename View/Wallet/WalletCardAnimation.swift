//
//  WalletCardAnimation.swift
//  animation
//
//  Created on 4/29/26.

import SwiftUI

@available(iOS 26.0, *)
struct WalletDemoView: View {
    @State private var info: Info = .init()

    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                VStack(spacing: -150) {
                    ForEach(payments) { payment in
                        cardView(payment)
                    }
                }
            }
            .scrollIndicators(.hidden)
            .safeAreaPadding(15)
            .navigationTitle(isNavigationTitleHidden ? "" : "Wallet")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add Card", systemImage: "plus") {}
                }

                ToolbarSpacer(.fixed, placement: .topBarTrailing)

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Search", systemImage: "magnifyingglass") {}
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Options", systemImage: "ellipsis") {}
                }
            }
            .onScrollGeometryChange(for: CGFloat.self) {
                $0.contentOffset.y + $0.contentInsets.top
            } action: { _, newValue in
                info.scrollOffset = newValue
            }
        }
    }

    var isNavigationTitleHidden: Bool {
        info.scrollOffset > 1
    }

    func cardView(_ card: PaymentType) -> some View {
        Rectangle()
            .foregroundStyle(.clear)
            .overlay {
                Image(card.cardBackground)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
            .clipShape(.rect(cornerRadius: 20))
            .frame(height: 220)
    }

    struct Info {
        var scrollOffset: CGFloat = 0
        var containerSize: CGSize = .zero
        var safeArea: EdgeInsets = .init()
    }
}

@available(iOS 26.0, *)
#Preview {
    WalletDemoView()
}
