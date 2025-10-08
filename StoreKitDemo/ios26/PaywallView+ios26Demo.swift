//
//  PaywallView+ios26Demo.swift
//  animation
//
//  Created on 10/7/25.

import StoreKit
import SwiftUI

struct PaywallView_ios26Demo: View {
    var body: some View {
        PaywallView(isCompact: false,
                    ids: PaywallModels.productIDs,
                    points: PaywallModels.iapPoints) {} links: {}
            .tint(Color.primary)
    }
}

struct PaywallView<Header: View, Links: View>: View {
    var isCompact: Bool
    var ids: [String]
    var points: [PaywallPoints]
    @ViewBuilder var header: Header
    @ViewBuilder var links: Links
    @State private var isLoaded: Bool = false
    var body: some View {
        SubscriptionStoreView(productIDs: ids, marketingContent: {})
            .subscriptionStoreControlStyle(CustomSubscriptionStyle(isCompact: isCompact, links: {
                links
            }, isLoaded: {
                isLoaded = true
            }), placement: .scrollView)
            .storeButton(.hidden, for: .policies)
            .storeButton(.visible, for: .restorePurchases)
            .animation(.easeInOut(duration: 0.35)) { content in
                content
                    .opacity(isLoaded ? 1 : 0)
            }
    }
}

private struct CustomSubscriptionStyle<Links: View>: SubscriptionStoreControlStyle {
    var isCompact: Bool
    @ViewBuilder var links: Links
    var isLoaded: () -> Void
    func makeBody(configuration: Configuration) -> some View {
        VStack(spacing: 10) {
            VStack(spacing: 25) {
                if isCompact {
                    CompactPickerSubscriptionStoreControlStyle().makeBody(configuration: configuration)
                } else {
                    PagedProminentPickerSubscriptionStoreControlStyle().makeBody(configuration: configuration)
                }
            }
        }
    }
}

#Preview {
    PaywallView_ios26Demo()
}
