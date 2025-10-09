//
//  ContentView.swift
//  StoreKitDemo
//
// play with subscription. product, store
import StoreKit
import SwiftUI

struct DefaultStoreKitView: View {
    var body: some View {
        SubscriptionStoreView(groupID: "4C5449F1")
            .subscriptionStoreControlStyle(.pagedProminentPicker, placement: .bottomBar)
            .subscriptionStorePickerItemBackground(.ultraThinMaterial)
            .storeButton(.visible, for: .restorePurchases)
            .storeButton(.hidden, for: .policies)
    }
}

struct ContentView: View {
    @State private var loadingStatus: (Bool, Bool) = (false, false)

    var body: some View {
        GeometryReader {
            let size = $0.size
            let smallerPhone = size.height < 700

            VStack(spacing: 0) {
                Group {
                    if smallerPhone {
                        SubscriptionStoreView(productIDs: PaywallModels.productIDs, marketingContent: {
                            marketingView()
                        })
                        .subscriptionStoreControlStyle(.compactPicker, placement: .bottomBar)
                    } else {
                        SubscriptionStoreView(productIDs: PaywallModels.productIDs, marketingContent: {
                            marketingView()
                        })
                        .subscriptionStoreControlStyle(.pagedProminentPicker, placement: .bottomBar)
                    }
                }
                .subscriptionStorePickerItemBackground(.ultraThinMaterial)
                .storeButton(.visible, for: .restorePurchases)
                .storeButton(.hidden, for: .policies)
                .onInAppPurchaseStart { _ in
                }
                .onInAppPurchaseCompletion { _, result in
                    switch result {
                    case let .success(result):
                        switch result {
                        case .success:
                            print("success")
                        case .pending:
                            print("pending")
                        case .userCancelled:
                            print("user cancelled")
                        @unknown default:
                            fatalError()
                        }
                    case let .failure(error):
                        print(error.localizedDescription)
                    }
                }
                .subscriptionStatusTask(for: "4C5449F1") {
                    if let result = $0.value {
                        let premiumUser = !result.filter { $0.state == .subscribed }.isEmpty
                        print(premiumUser)
                    }
                    loadingStatus.1 = true
                }

                /// privacy & TOS
                HStack(spacing: 3) {
                    Link("Terms of Service", destination: URL(string: "https://apple.com")!)

                    Text("And")

                    Link("Privacy Policy", destination: URL(string: "https://apple.com")!)
                }
                .font(.caption)
                .padding(.bottom, 10)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .opacity(isLoadingCompleted ? 1 : 0)
            .background(backdropView())
            .overlay {
                if !isLoadingCompleted {
                    ProgressView()
                        .font(.largeTitle)
                }
            }
            .animation(.easeInOut(duration: 0.35), value: isLoadingCompleted)
            .storeProductsTask(for: PaywallModels.productIDs) { @MainActor collection in
                if let products = collection.products, products.count == PaywallModels.productIDs.count {
                    try? await Task.sleep(for: .seconds(0.1))
                    loadingStatus.0 = true
                }
            }
            .environment(\.colorScheme, .light)
        }
    }

    var isLoadingCompleted: Bool {
        loadingStatus.0 && loadingStatus.1
    }

    func backdropView() -> some View {
        GeometryReader {
            let size = $0.size

            Image("AI_pink")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size.width, height: size.height)
                .scaleEffect(1.5)
                .blur(radius: 70, opaque: true)
                .overlay {
                    Rectangle()
                        .fill(.black.opacity(0.2))
                }
                .ignoresSafeArea()
        }
    }

    func marketingView() -> some View {
        VStack(spacing: 15) {
            /// App Screenshot view
            HStack(spacing: 25) {
                screenshotsView(["IMG_0210", "IMG_0214"], offset: 5)
                screenshotsView(["IMG_0215", "IMG_0211", "IMG_0216"], offset: -10)
                screenshotsView(["IMG_0212", "IMG_0213"], offset: -25)
                    .overlay(alignment: .trailing) {
                        screenshotsView(["IMG_0216", "IMG_0216", "IMG_0216"], offset: -15)
                            .visualEffect { content, proxy in
                                content
                                    .offset(x: proxy.size.width + 25)
                            }
                    }
            }
            .frame(maxHeight: .infinity)
            .offset(x: 20)
            /// Progress Blur Mask
            .mask {
                LinearGradient(colors: [
                    .white,
                    .white.opacity(0.9),
                    .white.opacity(0.7),
                    .white.opacity(0.4),
                    .clear,
                ], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                    .padding(.bottom, -40)
            }

            VStack(spacing: 6) {
                Spacer()

                VStack(spacing: 6) {
                    Text("App Name")
                        .font(.title3)

                    Text("Membership")
                        .font(.largeTitle.bold())

                    Text(dummyDescription)
                        .font(.callout)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .foregroundStyle(.black)
                .padding(.top, 15)
                .padding(.bottom, 10)
                .padding(.horizontal, 15)
            }
        }
    }

    func screenshotsView(_ content: [String], offset: CGFloat) -> some View {
        ScrollView(.vertical) {
            VStack(spacing: 10) {
                ForEach(content.indices, id: \.self) { index in
                    Image(content[index])
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
            }
            .offset(y: offset)
        }
        .scrollDisabled(true)
        .scrollIndicators(.hidden)
        .rotationEffect(.init(degrees: -30), anchor: .bottom)
        .scrollClipDisabled()
    }
}

#Preview {
    ContentView()
}
