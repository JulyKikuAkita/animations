//
//  iOS26+customSearch+FAB+Tabbar.swift
//  animation
//
//  Created on 5/27/26.
// Custom tabBar with floating action button in Bevel app style
//  https://apps.apple.com/us/app/bevel-ai-health-coach/id6456176249
//
// How the FAB works:
//   iOS 26's `Tab(role: .search)` reserves a trailing slot in the system tab bar
//   that is visually separated from the other tabs. We hijack that slot: instead
//   of letting it switch tabs, we intercept the selection change, snap the
//   selection back to the previous tab, and toggle an overlay (`isFABExpanded`).
//   The "+" glyph in that slot is then rotated 45° via UIKit to read as an "x"
//   while the overlay is open — SwiftUI has no direct handle on that image view,
//   so we reach into the UITabBar through a UIViewRepresentable extractor.
//
// How the overlay animates:
//   `TabOverlayModifier` wraps the content in a `GlassEffectContainer` so the
//   dimming scrim and the glass panel morph together with the iOS 26 liquid
//   glass effect (instead of two independent fades). The interpolating spring
//   on `isPresented` drives both the panel's slide-in and the scrim's opacity.
import SwiftUI

enum AppTab {
    case home, saved, liked, account
}

@available(iOS 26.0, *)
struct TabBarWithFABButtonsDemoView: View {
    @State private var activeTab: AppTab? = .home
    @State private var isFABExpanded: Bool = false
    @State private var tabBar: UITabBar?

    var body: some View {
        // `value:` is each tab's selection identity. iOS 26's Tab API ties
        // selection to a typed value (here `AppTab?`) instead of an index:
        // when the user taps a tab, SwiftUI writes its `value` into the
        // `selection` binding (`activeTab`), and conversely setting
        // `activeTab` programmatically activates the tab whose `value` matches.
        // The type must match the binding — `AppTab?` — which is why the
        // search-role tab below can use `.none` (nil); that nil is the
        // sentinel we detect in `onChange(of: activeTab)` to fire the FAB
        // instead of switching tabs.
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

            // FAB action can be displayed over the tabView (disable tab interactions)
            // or inside each tab as below example
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

            // The search-role tab is repurposed as the FAB trigger.
            // `value: .none` is what lets `onChange(of: activeTab)` detect a
            // tap on this slot — selection briefly becomes nil, which we then
            // revert while toggling the overlay.
            Tab(value: .none, role: .search) {} label: {
                Image(systemName: "plus")
            }
        }
        .tabViewBottomAccessory {
            AccessoryView { _, _ in
                isFABExpanded = false
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        // Intercept selection of the search-role slot and turn it into a
        // FAB toggle instead of an actual tab switch.
        //
        // Why the dance with `setAnimationsEnabled(false)` + async restore:
        //   When the user taps the "+" tab, SwiftUI sets `activeTab = nil`
        //   and UITabBar kicks off its replacement animation. We immediately
        //   write the old value back, but without suppressing the animation
        //   the user sees a flicker of the system "no selection" state. We
        //   disable animations for the synchronous revert, then re-enable
        //   them on the next runloop tick so the FAB-icon rotation animates
        //   normally.
        .onChange(of: activeTab) { oldValue, newValue in
            if newValue == nil {
                UITabBar.setAnimationsEnabled(false)
                activeTab = oldValue
                DispatchQueue.main.async {
                    UITabBar.setAnimationsEnabled(true)
                    isFABExpanded.toggle()
                }
            }
        }
        // Grab a reference to the underlying UITabBar so we can rotate the
        // "+" glyph directly — SwiftUI doesn't expose a handle to that view.
        .background {
            TabBarExtractor { tabBar = $0 }
        }
        // Required so the UIKit-driven rotation composites cleanly with the
        // SwiftUI overlay/glass effect above it.
        .compositingGroup()
        .onChange(of: isFABExpanded) { _, _ in
            animateFABIcon()
        }
    }

    // Rotates the "+" image view inside the tab bar to a 45° "x" (and back)
    // when the overlay opens/closes. We can't animate this from SwiftUI
    // because the glyph lives inside UITabBar's private view hierarchy, so
    // we walk the subview tree, match by description, and animate the layer
    // transform via UIKit.
    private func animateFABIcon() {
        let fabImageViews = (tabBar?.descendants(ofType: UIImageView.self) ?? [])
            .filter { $0.description.contains("plus") }

        for fabImageView in fabImageViews {
            let transform: CGAffineTransform = isFABExpanded ? .init(rotationAngle: 45 * .pi / 180) : .identity
            UIView.animate(withDuration: 0.2) {
                fabImageView.layer.setAffineTransform(transform)
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

// Per-tab overlay used as the FAB's expanded surface.
// `GlassEffectContainer` makes the dim scrim and the glass panel share one
// liquid-glass animation pass, so they morph together rather than crossfading
// independently. `isViewAppearing` gates the overlay until the host view is
// on-screen — without it, the glass effect can flash on first present because
// the container is asked to render before its bounds are settled.
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
                                .frame(maxHeight: .infinity, alignment: .bottom)
                                .padding(.horizontal, 15)
                                .padding(.bottom, 10)
                        }
                    }
                    .allowsHitTesting(isPresented)
                    .animation(
                        .interpolatingSpring(duration: 0.3, bounce: 0, initialVelocity: 0),
                        value: isPresented
                    )
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

// Walks up from a hidden background UIView to find the hosting
// UITabBarController, then hands its UITabBar back to SwiftUI. The
// `superview?.superview?.subviews.last?.subviews.first?.next` chain is
// fragile and tied to the iOS 26 TabView view hierarchy — if Apple
// reorganizes it, this lookup will silently return nil and the FAB icon
// will simply stop rotating (the rest of the UI keeps working).
private struct TabBarExtractor: UIViewRepresentable {
    var result: (UITabBar) -> Void
    func makeUIView(context _: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        DispatchQueue.main.async {
            if let tabBarController = view.superview?.superview?.subviews.last?.subviews.first?.next as? UITabBarController {
                result(tabBarController.tabBar)
            }
        }

        return view
    }

    func updateUIView(_: UIView, context _: Context) {}
}
