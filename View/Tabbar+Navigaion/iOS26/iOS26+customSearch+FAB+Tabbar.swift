//
//  iOS26+customSearch+FAB+Tabbar.swift
//  animation
//
//  Learning point
//  ──────────────
//  Repurpose iOS 26's `Tab(role: .search)` slot — which the system
//  visually separates from the other tabs — as a FLOATING ACTION
//  BUTTON. Instead of letting that tab become "active", we intercept
//  the selection change (it briefly becomes nil), snap selection back
//  to the previous tab, and toggle an overlay panel. The "+" glyph
//  rotates 45° to read as an "x" while open — done in UIKit because
//  SwiftUI has no direct handle on that glyph's image view.
//  (Bevel app style: https://apps.apple.com/us/app/bevel-ai-health-coach/id6456176249)
//
//  Key APIs
//  ────────
//  • `Tab(value: .none, role: .search) {} label: { ... }` — the slot
//    we hijack. `value: .none` is the sentinel that lets `onChange`
//    detect a tap and revert it.
//  • `TabView(selection: $activeTab)` with typed `AppTab?` selection.
//  • `UITabBar.setAnimationsEnabled(false)` + async restore — kills
//    the flicker of the system "no selection" state during the revert.
//  • `UIViewRepresentable` (`TabBarExtractor`) — walks the view tree
//    to grab the underlying `UITabBar`. Fragile by design — see the
//    inline note about the superview-chain assumption.
//  • `GlassEffectContainer` in `TabOverlayModifier` — makes the dim
//    scrim and the glass panel share ONE liquid-glass animation pass
//    so they morph together rather than crossfading independently.
//  • `.tabViewBottomAccessory { ... }` — bonus iOS 26 API showing a
//    persistent accessory above the tab bar.
//  • `.tabBarMinimizeBehavior(.onScrollDown)` — paired with above.
//
//  How to apply
//  ────────────
//  Use when you want a FAB that LIVES IN the system tab bar (so it
//  inherits liquid-glass styling, safe-area handling, and accessibility
//  for free) instead of overlaying a custom button. Accept the cost:
//  you depend on the `role: .search` layout reservation and on poking
//  into `UITabBar`'s subviews — both can shift in future iOS updates.
//
//  See also
//  ────────
//  • CustomMorphingTabBarIOS26.swift — FAB OUTSIDE the tab bar (a
//    separate "+" capsule beside it). More portable, less integrated.
//  • CustomMorphingTab+BottomBar+IOS26.swift — yet another FAB style
//    where the WHOLE bar morphs into an action bar.
//  • LiquidGlassSearchableTabbar.swift — `.tabViewBottomAccessory`
//    used for its intended purpose (a mini-player), not as a FAB.
//
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
