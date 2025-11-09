//
//  TippingPaywallDemoView.swift
//  animation
//
//  Created on 11/9/25.
//
// - >= 5 puchase items: use frame for storeview (aka scrollview)
//  < 5 items: use fixedSize modifier to the container // .frame(maxHeight: 400)

import StoreKit
import SwiftUI

struct TippingPaywallDemoView: View {
    @State private var showTippingSheet: Bool = false
    @State private var animateContents: Bool = false
    var body: some View {
        NavigationStack {
            List {
                Button("Show sheet") {
                    noAnimation {
                        showTippingSheet.toggle()
                    }
                }
            }
            .navigationTitle("Support Us")
        }
        .fullScreenCover(isPresented: $showTippingSheet) {
            GeometryReader {
                let size = $0.size

                Rectangle()
                    .fill(.black.opacity(animateContents ? 0.5 : 0))
                    .ignoresSafeArea()

                TippingView(ids: productIds) {
                    VStack(alignment: .center, spacing: 8) {
                        Text("Demo")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text("Dummy app description...")
                            .font(.callout)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 15)
                    }
                    .padding(.vertical, 5)
                } icon: { product in
                    if let index = productIds.firstIndex(of: product.id) {
                        Group {
                            switch index {
                            case 0: Text("🙌")
                            case 1: Text("☺️")
                            case 2: Text("😍")
                            default: Text("❤️")
                            }
                        }
                        .font(.system(size: 45))
                        .padding(.horizontal, 5)
                    }
                } footer: {} onDismiss: {
                    withAnimation(
                        .smooth(duration: 0.35, extraBounce: 0),
                        completionCriteria: .logicallyComplete
                    ) {
                        animateContents = true
                    } completion: {
                        noAnimation {
                            showTippingSheet = false
                        }
                    }
                }
                .fontDesign(.rounded)
                // .productDescription(.hidden)
                .tint(.indigo)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .offset(y: animateContents ? 0 : size.height)
            }
            .presentationBackground(.clear)
            .onAppear {
                withAnimation(.smooth(duration: 0.35, extraBounce: 0)) {
                    animateContents = true
                }
            }
        }
    }

    var productIds: [String] {
        ["animation.test.mini", "animation.test.support", "animation.test.prosupport", "animation.test.promaxsupport"]
    }
}

struct TippingView<Header: View, Icon: View, Footer: View>: View {
    var maxWidth: CGFloat = 330
    var thankMessage: String = "Thanks for your support!"
    var ids: [String]
    @ViewBuilder var header: Header
    @ViewBuilder var icon: (Product) -> Icon
    @ViewBuilder var footer: Footer

    /// Callbacks
    var onStart: (Product) -> Void = { _ in }
    var onCompletion: (Product, Result<Product.PurchaseResult, any Error>) -> Void = { _, _ in }
    var onDismiss: () -> Void = {}
    /// @View Properties
    @Environment(\.colorScheme) private var colorScheme
    @State private var isLoading: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var updatesListener: Task<Void, Error>? = nil
    var body: some View {
        let glassTint: Color = colorScheme == .dark ? .gray.opacity(0.15) : .white.opacity(0.8)
        VStack(spacing: 10) {
            header
                .padding(.horizontal, 15)
                .padding(.top, 12)

            /// Native Store View
            StoreView(ids: ids) { product in
                icon(product)
            }
            .fixedSize(horizontal: false, vertical: true)
            .productViewStyle(.compact)
            .customGlassButtonStyle()
            /// disabling dismiss button
            .storeButton(.hidden, for: .cancellation)

            footer

            Button {} label: {
                Text("Dismiss")
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                    .opacity(isLoading ? 0 : 1)
                    .overlay {
                        ProgressView()
                            .controlSize(.mini)
                            .tint(.white)
                            .opacity(isLoading ? 1 : 0)
                    }
            }
            .customGlassButtonStyle()
            .tint(.red)
            .padding(.horizontal, 15)
            .padding(.bottom, 12)
        }
        .allowsHitTesting(!isLoading)
        .opacity(isLoading ? 0.7 : 1)
        .animation(.easeInOut(duration: 0.2), value: isLoading)
        .customGlassBackground(shape: .rect(cornerRadius: 25), glassTint: glassTint)
        .geometryGroup()
        .frame(maxWidth: maxWidth)
        .padding(.horizontal, 15)
        .onInAppPurchaseStart { product in
            onStart(product)
            isLoading = true
        }.onInAppPurchaseCompletion { product, result in
            switch result {
            case let .success(result):
                switch result {
                case let .success(verificationResult):
                    switch verificationResult {
                    case let .verified(transaction):
                        await transaction.finish()
                        alertMessage = thankMessage
                    case .unverified:
                        alertMessage = "The purchase was successful, but app store couldn't verify it. Please try again."
                    }
                case .pending:
                    alertMessage = "The purchase is pending!"
                case .userCancelled:
                    alertMessage = "User cancelled the purchase."
                @unknown default:
                    fatalError("unknown error")
                }
            case .failure:
                alertMessage = "There was an error processing your purchase. Please try again later."
            }
            onCompletion(product, result)
            showAlert = true
            isLoading = false
        }
        .alert(alertMessage, isPresented: $showAlert) {
            Button("Done", role: .cancel) {}
        }
        .onAppear {
            updatesListener = Task.detached {
                for await updates in Transaction.updates {
                    if case let .verified(transaction) = updates {
                        await transaction.finish()
                    }
                }
            }
        }
        .onDisappear {
            updatesListener?.cancel()
        }
    }
}

private extension View {
    @ViewBuilder
    func customGlassButtonStyle() -> some View {
        if #available(iOS 26, *) {
            self
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.capsule)
        } else {
            buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
        }
    }

    @ViewBuilder
    func customGlassBackground(shape: some Shape, glassTint: Color = .clear) -> some View {
        if #available(iOS 26, *) {
            self
                .glassEffect(.regular.tint(glassTint).interactive(), in: shape)
        } else {
            clipShape(shape)
                .background {
                    shape
                        .fill(.background)
                        .shadow(color: .black.opacity(0.1), radius: 5, x: 5, y: 5)
                        .shadow(color: .black.opacity(0.05), radius: 5, x: -5, y: -5)
                }
        }
    }
}

#Preview {
    TippingPaywallDemoView()
}
