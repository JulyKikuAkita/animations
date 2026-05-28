//
//  iOS26+customSearch+FAB+Tabbar.swift
//  animation
//
//  Created on 5/27/26.
// Custom tabbar with bevel app style
//  https://apps.apple.com/us/app/bevel-ai-health-coach/id6456176249
import SwiftUI

enum AppTab {
    case home, saved, liked, account
}

@available(iOS 26.0, *)
struct TabBarWithFABButtonsDemoView: View {
    @State private var activeTab: AppTab? = .home
    @State private var isFABExpanded: Bool = false
    var body: some View {
        TabView(selection: $activeTab) {
            Tab("Home", systemImage: "house", value: .home) {
                ScrollView(.vertical) {
                    Rectangle()
                        .foregroundStyle(.clear)
                        .frame(height: 2000)
                }
                .tabOverlay(isPresented: isFABExpanded) {
                    Text("isFABExpanded")
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)
                } onDismiss: {
                    isFABExpanded = false
                }
            }

            Tab("Saved", systemImage: "bookmark", value: .saved) {
                Text("Saved")
                    .tabOverlay(isPresented: isFABExpanded) {
                        Text("isFABExpanded")
                            .frame(maxWidth: .infinity)
                            .frame(height: 220)
                    } onDismiss: {
                        isFABExpanded = false
                    }
            }

            Tab("Linked", systemImage: "suit.heart", value: .liked) {}

            Tab("Account", systemImage: "person", value: .account) {}

            Tab(value: .none, role: .search) {} label: {
                Image(systemName: "plus")
            }
        }
        .tabViewBottomAccessory {
            AccessoryView { _, _ in
            }
        }
        .onChange(of: activeTab) { oldValue, newValue in
            if newValue == nil {
                /// Disable native tab replacement animation
                UITabBar.setAnimationsEnabled(false)
                activeTab = oldValue
                DispatchQueue.main.async {
                    UITabBar.setAnimationsEnabled(true)
                    isFABExpanded.toggle()
                }
            }
        }
    }
}

@available(iOS 26.0, *)
struct AccessoryView: View {
    var onPlacementChanged: (_ oldValue: TabViewBottomAccessoryPlacement?,
                             _ newValue: TabViewBottomAccessoryPlacement?) -> Void
    @Environment(\.tabViewBottomAccessoryPlacement) private var placement
    var body: some View {
        Text("test")
            .onChange(of: placement) { oldValue, newValue in
                onPlacementChanged(oldValue, newValue)
            }
    }
}

@available(iOS 26.0, *)
struct TabOverlayModifier<ViewContent: View>: ViewModifier {
    var isPresented: Bool
    @ViewBuilder var viewContent: ViewContent
    var onDismiss: () -> Void
    @State private var isViewAppearing: Bool = false
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay {
                if isViewAppearing {
                    GlassEffectContainer {
                        if isPresented {
                            Rectangle()
                                .fill(.black.opacity(0.25))
                                .contentShape(.rect)
                                .onTapGesture {
                                    onDismiss()
                                }
                                .ignoresSafeArea()
                                .transition(.opacity)
                        }

                        if isPresented {
                            viewContent
                                .clipShape(.rounded(cornerRadius: 30))
                                .glassEffect(.regular.interactive(), in: .rounded(cornerRadius: 30))
                                .frame(maxWidth: .infinity, alignment: .bottom)
                                .padding(.horizontal, 15)
                                .padding(.bottom, 10)
                        }
                    }
                    .allowsHitTesting(isPresented)
                    .animation(.interpolatingSpring(duration: 0.3, bounce: 0, initialVelocity: 0), value: isPresented)
                }
            }
            .onAppear {
                isViewAppearing = true
            }
            .onDisappear {
                isViewAppearing = false
            }
    }
}

@available(iOS 26.0, *)
#Preview {
    TabBarWithFABButtonsDemoView()
}

@available(iOS 26.0, *)
extension View {
    @ViewBuilder
    func tabOverlay(isPresented: Bool,
                    @ViewBuilder content: () -> some View,
                    onDismiss: @escaping () -> Void) -> some View
    {
        modifier(TabOverlayModifier(isPresented: isPresented,
                                    viewContent: content,
                                    onDismiss: onDismiss))
    }
}
