//
//  CustomTabbarUIToolKitiOS26.swift
//  animation
//
//  Learning point
//  ──────────────
//  TWO TECHNIQUES for putting a custom SwiftUI cell inside a UIKit
//  `UISegmentedControl` (which only natively accepts `String` or
//  `UIImage` items):
//
//    Type 1 — `CustomTabbarUITK` (renders SwiftUI → `UIImage`):
//      Uses `ImageRenderer` to rasterize the SwiftUI tab cell and
//      hand it to `setImage(_:forSegmentAt:)`. Pros: zero hierarchy
//      surprises, perfect alignment. Cons: image is STATIC — no
//      dynamic content (e.g. live badges) and Dynamic Type changes
//      need a re-render.
//
//    Type 2 — `CustomTabbarTypeTwo` (SwiftUI overlay over UIKit):
//      Renders an empty segmented control, then `.overlay`s a real
//      SwiftUI HStack on top. Pros: live SwiftUI content, animatable.
//      Cons: alignment is on you, hit-testing is the UIKit control's.
//
//  Both demos compose with `GlassEffectContainer` + a glass-capsule
//  trailing action button to land on iOS 26's liquid-glass aesthetic.
//
//  Key APIs
//  ────────
//  • `UIViewRepresentable` + `UISegmentedControl`
//  • `ImageRenderer(content:)` — SwiftUI → CGImage/UIImage rasterizer.
//  • `.glassEffect(.regular.interactive(), in: .capsule)`
//  • `.toolbarVisibility(.hidden, for: .tabBar)` per Tab — to hide the
//    system tab bar while keeping `TabView` selection behavior.
//  • `.safeAreaBar` / `.safeAreaInset` — reserves layout space for the
//    custom bar.
//
//  How to apply
//  ────────────
//  Pick Type 1 when the cell is decorative (icon + static label) and
//  Type 2 when the cell needs LIVE SwiftUI (animated symbols, live
//  badges, conditional accents). When neither fits, drop to a fully
//  custom HStack — see CustomTabbariOS26.swift.
//
//  See also
//  ────────
//  • CustomMorphingTabBarIOS26.swift — same UIKit bridge, generic
//    `MorphingTabProtocol`, paired with an expanding action grid.
//  • CustomMorphingTab+BottomBar+IOS26.swift — same UIKit bridge,
//    paired with a NAV-driven 2-state morph.
//

import SwiftUI

@available(iOS 26.0, *)
struct CustomTabbarUITKDemoView: View {
    @State private var activeTab: CustomTabiOS26 = .home
    var body: some View {
        TabView(selection: $activeTab) {
            Tab(value: .home) {
                ScrollView(.vertical) {
                    VStack(spacing: 10) {
                        DummyRectangles(color: .pink, count: 15)
                    }
                }
                .safeAreaBar(edge: .bottom, spacing: 0, content: {
                    Text(".") // cannot use empty view
                        .blendMode(.destinationOver)
                        .frame(height: 55) /// tabbar height
                })
                /// hide default tab bar
                .toolbarVisibility(.hidden, for: .tabBar)
            }

            Tab(value: .notificatinos) {
                Text("Notifications")
                    .safeAreaBar(edge: .bottom, spacing: 0, content: {
                        Text(".") // cannot use empty view
                            .blendMode(.destinationOver)
                            .frame(height: 55) /// tabbar height
                    })
                    .toolbarVisibility(.hidden, for: .tabBar)
            }

            Tab(value: .settings) {
                Text("Settings")
                    .safeAreaBar(edge: .bottom, spacing: 0, content: {
                        Text(".") // cannot use empty view
                            .blendMode(.destinationOver)
                            .frame(height: 55) /// tabbar height
                    })
                    .toolbarVisibility(.hidden, for: .tabBar)
            }
        }
        /// do not use new safeAreaBar API here as buggy behavior
        .safeAreaInset(edge: .bottom, spacing: 0) {
            CustomTabbarUIToolKitiOS26TypOneDemoView()
//            CustomTabbarUIToolKitiOS26TypTwoDemoView()
                .padding(.horizontal, 20)
        }
    }
}

@available(iOS 26.0, *)
struct CustomTabbarUIToolKitiOS26TypOneDemoView: View {
    @State private var activeTab: CustomTabiOS26 = .home
    var body: some View {
        VStack {
            GlassEffectContainer(spacing: 10) {
                HStack(spacing: 10) {
                    GeometryReader { proxy in
                        CustomTabbarUITK(
                            size: proxy.size,
                            activeTab: $activeTab
                        ) { tab in
                            VStack(spacing: 5) {
                                Image(systemName: tab.symbol)
                                    .font(.title3)
                                Text(tab.rawValue)
                                    .font(.system(size: 10))
                                    .fontWeight(.medium)
                            }
                            .symbolVariant(.fill)
                            .frame(maxWidth: .infinity)
                        }
                        .glassEffect(.regular.interactive(), in: .capsule)
                    }

                    ZStack {
                        ForEach(CustomTabiOS26.allCases, id: \.rawValue) { tab in
                            Image(systemName: tab.actionSymbol)
                                .font(.system(size: 22, weight: .medium))
                                .blurFadeViews(activeTab == tab)
                        }
                    }
                    .frame(width: 55, height: 55)
                    .glassEffect(.regular.interactive(), in: .capsule)
                    .animation(.smooth(duration: 0.55, extraBounce: 0), value: activeTab)
                }
            }
            .frame(height: 55)
        }
        .padding(.horizontal, 20)
    }
}

@available(iOS 26.0, *)
struct CustomTabbarUIToolKitiOS26TypTwoDemoView: View {
    @State private var activeTab: CustomTabiOS26 = .home
    var body: some View {
        VStack {
            GlassEffectContainer(spacing: 10) {
                HStack(spacing: 10) {
                    GeometryReader { proxy in
                        CustomTabbarTypeTwo(
                            size: proxy.size,
                            activeTab: $activeTab
                        )
                        .overlay {
                            HStack(spacing: 0) {
                                ForEach(CustomTabiOS26.allCases, id: \.rawValue) { tab in
                                    VStack(spacing: 3) {
                                        Image(systemName: tab.symbol)
                                            .font(.title3)
                                        Text(tab.rawValue)
                                            .font(.system(size: 10))
                                            .fontWeight(.medium)
                                    }
                                    .symbolVariant(.fill)
                                    .foregroundStyle(activeTab == tab ? .blue : .primary)
                                    .frame(maxWidth: .infinity)
                                }
                            }
                            .animation(
                                .easeInOut(duration: 0.25),
                                value: activeTab
                            )
                        }
                        .glassEffect(.regular.interactive(), in: .capsule)
                    }

                    ZStack {
                        ForEach(CustomTabiOS26.allCases, id: \.rawValue) { tab in
                            Image(systemName: tab.actionSymbol)
                                .font(.system(size: 22, weight: .medium))
                                .blurFadeViews(activeTab == tab)
                        }
                    }
                    .frame(width: 55, height: 55)
                    .glassEffect(.regular.interactive(), in: .capsule)
                    .animation(.smooth(duration: 0.55, extraBounce: 0), value: activeTab)
                }
            }
            .frame(height: 55)
        }
        .padding(.horizontal, 20)
    }
}

// Type 1: UIToolKit Implementation, customize tint color
struct CustomTabbarUITK<TabItemView: View>: UIViewRepresentable {
    var size: CGSize
    var activeTint: Color = .blue
    var barTint: Color = .gray.opacity(0.15)
    @Binding var activeTab: CustomTabiOS26
    @ViewBuilder var tabItemView: (CustomTabiOS26) -> TabItemView

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> some UISegmentedControl {
        let items = CustomTabiOS26.allCases.map(\.rawValue)
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = activeTab.index
        setTabItemVIewIntoAnImage(control)

        DispatchQueue.main.async {
            for subview in control.subviews {
                if subview is UIImageView, subview != control.subviews.last! {
                    /// background view
                    // subview.backgroundColor = .systemPink // test update bg color
                    subview.alpha = 0
                }
            }
        }

        control.selectedSegmentTintColor = UIColor(barTint)
        control.setTitleTextAttributes([
            .foregroundColor: UIColor(activeTint),
        ], for: .selected)
        control.setTitleTextAttributes([
            .foregroundColor: UIColor(.brown),
        ], for: .normal)

        control.addTarget(context.coordinator, action:
            #selector(context.coordinator.tabSelected(_:)), for: .valueChanged)
        return control
    }

    /// option 1 to convert a custom view to segmented control
    private func setTabItemVIewIntoAnImage(_ control: UISegmentedControl) {
        for (index, tab) in CustomTabiOS26.allCases.enumerated() {
            let renderer = ImageRenderer(content: tabItemView(tab))

            renderer.scale = 4 // customize as needed
            let image = renderer.uiImage
            control.setImage(image, forSegmentAt: index)
        }
    }

    func updateUIView(_: UIViewType, context _: Context) {}

    func sizeThatFits(_: ProposedViewSize, uiView _: UISegmentedControl, context _: Context) -> CGSize? {
        let baseHeight = min(55, size.height)
        let paddedHeight = baseHeight + 12 // add vertical padding (top + bottom = 12)
        return CGSize(width: size.width, height: paddedHeight)
    }

    @MainActor
    class Coordinator: NSObject {
        var parent: CustomTabbarUITK
        init(parent: CustomTabbarUITK) {
            self.parent = parent
        }

        @objc func tabSelected(_ control: UISegmentedControl) {
            parent.activeTab = CustomTabiOS26.allCases[control.selectedSegmentIndex]
        }
    }
}

// Type 2:
struct CustomTabbarTypeTwo: UIViewRepresentable {
    var size: CGSize
    var barTint: Color = .gray.opacity(0.15)
    @Binding var activeTab: CustomTabiOS26

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> some UISegmentedControl {
        let items = CustomTabiOS26.allCases.compactMap { _ in "" }
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = activeTab.index

        DispatchQueue.main.async {
            for subview in control.subviews {
                if subview is UIImageView, subview != control.subviews.last! {
                    /// background view
                    // subview.backgroundColor = .systemPink // test update bg color
                    subview.alpha = 0
                }
            }
        }

        control.selectedSegmentTintColor = UIColor(barTint)
        control.setTitleTextAttributes([
            .foregroundColor: UIColor(.brown),
        ], for: .normal)

        control.addTarget(context.coordinator, action:
            #selector(context.coordinator.tabSelected(_:)), for: .valueChanged)
        return control
    }

    func updateUIView(_: UIViewType, context _: Context) {}

    func sizeThatFits(_: ProposedViewSize, uiView _: UISegmentedControl, context _: Context) -> CGSize? {
        size
    }

    @MainActor
    class Coordinator: NSObject {
        var parent: CustomTabbarTypeTwo
        init(parent: CustomTabbarTypeTwo) {
            self.parent = parent
        }

        @objc func tabSelected(_ control: UISegmentedControl) {
            parent.activeTab = CustomTabiOS26.allCases[control.selectedSegmentIndex]
        }
    }
}

@available(iOS 26.0, *)
#Preview {
    CustomTabbarUITKDemoView()
}

@available(iOS 26.0, *)
#Preview {
    VStack {
        CustomTabbarUIToolKitiOS26TypOneDemoView()
            .frame(height: 150)
        CustomTabbarUIToolKitiOS26TypTwoDemoView()
            .frame(height: 150)
        Spacer(minLength: 0)
    }
}
