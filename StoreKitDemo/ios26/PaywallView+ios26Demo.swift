//
//  PaywallView+ios26Demo.swift
//  animation
//
//  Created on 10/7/25.

import StoreKit
import SwiftUI

struct PaywallViewiOS26Demo: View {
    @State private var isCompact: Bool = false
    @State private var showPaywall: Bool = false
    var body: some View {
        NavigationStack {
            List {
                Toggle("Compact", isOn: $isCompact)
                Button("Show Paywall") {
                    showPaywall.toggle()
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(isCompact: isCompact,
                        ids: PaywallModels.productIDs,
                        points: PaywallModels.iapPoints)
            {
                appInformationView()
            } links: {
                MockLinkView()
            } loadingView: {
                /// customize loading view as needed
                ProgressView()
            }
            .tint(Color.primary)
            .interactiveDismissDisabled()
            .onInAppPurchaseStart { product in
                print("Purchase started for \(product.displayName)")
            }.onInAppPurchaseCompletion { _, result in
                print(result)
            }
            /// the task is triggered on view appears or the subscription status changes
            .subscriptionStatusTask(for: "4C5449F1") { status in
                print("Check for subscription status: \(status)")
            }
        }
    }

    func appInformationView() -> some View {
        VStack(spacing: 15) {
            VStack(alignment: .trailing, spacing: 0) {
                Text("App Name")
                    .font(.title.bold())

                Text("Premium")
                    .font(.caption.bold())
                    .foregroundStyle(.background)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.primary, in: .capsule)
                    .offset(x: 5)
            }
            .lineLimit(1)
            .padding(.top, 10)

            Image(systemName: "apple.logo")
                .font(.system(size: 60))
                .foregroundStyle(.background)
                .frame(width: 100, height: 100)
                .background(.primary, in: .rect(cornerRadius: 25))
                .padding(.vertical, 25)
        }
    }
}

struct MockLinkView: View {
    var body: some View {
        HStack(spacing: 5) {
            Link("Terms of Service", destination: URL(string: "https://apple.com")!)
            Text("&")
            Link("Privacy Policy", destination: URL(string: "https://apple.com")!)
        }
        .font(.caption)
        .foregroundStyle(.gray)
    }
}

struct PaywallView<Header: View, Links: View, Loader: View>: View {
    var isCompact: Bool
    var ids: [String]
    var points: [PaywallPoints]
    @ViewBuilder var header: Header
    @ViewBuilder var links: Links
    @ViewBuilder var loadingView: Loader
    @State private var isLoaded: Bool = false
    var body: some View {
        SubscriptionStoreView(productIDs: ids, marketingContent: {
            marketingContentView()
        })
        .subscriptionStoreControlStyle(
            CustomSubscriptionStyle(isCompact: isCompact, links: {
                links
            }, isLoaded: {
                isLoaded = true
            }), placement: .scrollView
        )
        .storeButton(.hidden, for: .policies)
        .storeButton(.visible, for: .restorePurchases)
        .animation(.easeInOut(duration: 0.35)) { content in
            content
                .opacity(isLoaded ? 1 : 0)
        }
        .overlay {
            ZStack {
                if !isLoaded {
                    loadingView
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.35), value: isLoaded)
        }
        .scrollClipDisabled()
        .scrollIndicators(.hidden)
    }

    func marketingContentView() -> some View {
        VStack(spacing: 15) {
            header

            if isLoaded {
                VStack(alignment: .leading, spacing: 15) {
                    ForEach(points.indices, id: \.self) { index in
                        let point = points[index]
                        AnimatedIAPointView(index: index, point: point)
                    }
                }
                .transition(.identity)
            }

            Spacer(minLength: 0)
        }
        .padding([.horizontal, .top], 15)
    }
}

private struct AnimatedIAPointView: View {
    var index: Int
    var point: PaywallPoints
    @State private var animateSymbol: Bool = false
    @State private var animateContent: Bool = false
    var body: some View {
        HStack(spacing: 0) {
            ZStack {
                if animateSymbol {
                    Image(systemName: point.symbol)
                        .font(.title2)
                        .symbolVariant(.fill)
                        .foregroundStyle(point.symbolTint)
                        .transition(.blurReplace)
                }
            }
            .frame(width: 35, height: 35)

            Text(point.content)
                .font(.callout)
                .fontWeight(.medium)
                .padding(.leading, 10)
                .foregroundStyle(.primary)
                .visualEffect { [animateContent] content, proxy in
                    content
                        .opacity(animateContent ? 1 : 0)
                        .offset(x: animateContent ? 0 : -proxy.size.width)
                }
                .clipped()

            Spacer(minLength: 0)
        }
        .task {
            /// index base delay animation on list items
            guard !animateSymbol else { return }
            try? await Task.sleep(for: .seconds(Double(index) * 0.4))
            withAnimation(.snappy(duration: 0.3, extraBounce: 0)) {
                animateSymbol = true
            }

            try? await Task.sleep(for: .seconds(Double(index) * 0.11))
            withAnimation(.snappy(duration: 0.3, extraBounce: 0)) {
                animateContent = true
            }
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

            links
                .buttonStyle(.plain)
                .padding(.vertical, isiOS26 ? 0 : 5)
        }
        .onAppear(perform: isLoaded)
        .offset(y: 12)
    }

    var isiOS26: Bool {
        if #available(iOS 26, *) {
            return true
        }
        return false
    }
}

#Preview {
    PaywallView_ios26Demo()
}
