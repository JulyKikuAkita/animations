//
//  SFSymbolAnimatedTabBar.swift
//  animation
//
//  SwiftUI does not support animated tab item images with symbol effects
//  Thus, use UIKit UIImageVies to locate compostingGroup referred as UIInheritedView
//  Locate the group of views (showing in reverse order) and manually add symbol effects
//
import SwiftUI

protocol AnimatedTabSelectionProtocol: CaseIterable, Hashable {
    var symbolImage: String { get }
    var title: String { get }
}

struct AnimatedSFSymbolTabView<Selection: AnimatedTabSelectionProtocol, Content: TabContent<Selection>>: View {
    @Binding var selected: Selection
    @TabContentBuilder<Selection> var content: () -> Content
    var effects: (Selection) -> [any DiscreteSymbolEffect & SymbolEffect]
    /// View Properties
    @State private var imageViews: [Selection: UIImageView] = [:]
    var body: some View {
        TabView(selection: $selected) {
            content()
        }
        .tabViewStyle(.tabBarOnly)
        .background(ExtractImageViewFromTabView {
            imageViews = $0
        })
        .compositingGroup()
        /// animate the image view when tab changes
        .onChange(of: selected) { _, newValue in
            let symbolEffects = effects(newValue)
            guard let imageView = imageViews[newValue] else {
                print("cannot locate image")
                return
            }
            for effect in symbolEffects {
                imageView.addSymbolEffect(effect, options: .nonRepeating)
            }
        }
    }
}

private struct ExtractImageViewFromTabView<Value: AnimatedTabSelectionProtocol>: UIViewRepresentable {
    var result: ([Value: UIImageView]) -> Void

    func makeUIView(context _: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        DispatchQueue.main.async {
            if let compostingGroup = view.superview?.superview {
                guard let tabHostingController = compostingGroup.subviews.last else { return }
                guard let tabController = tabHostingController.subviews.first?.next as? UITabBarController else { return }
                extractImageViews(tabController.tabBar)
            }
        }
        return view
    }

    func updateUIView(_: UIView, context _: Context) {}

    // iOS 26+ tabbar each icon has 2 images: tint + regular
    // prev iOS 18 and before tabbar only has regular image
    @MainActor
    private func extractImageViews(_ tabBar: UITabBar) {
        let imageViews = tabBar.subViews(type: UIImageView.self)
            /// filter non sy,bol images
            .filter { $0.image?.isSymbolImage ?? false }
            /// iOS 26+ only retrieve tinted image
            .filter { isiOS26OrLater ? ($0.tintColor == tabBar.tintColor) : true }

        var dict: [Value: UIImageView] = [:]

        for tab in Value.allCases {
            /// finding the associated image using the symbol name
            if let imageView = imageViews.first(where: { $0.description.contains(tab.symbolImage) }) {
                dict[tab] = imageView
                print("tab.symbolImage: \(tab.symbolImage) ")
            }
        }
        result(dict)
    }
}

enum AppTab: AnimatedTabSelectionProtocol {
    case call
    case notifications
    case settings

    var symbolImage: String {
        switch self {
        case .call: "phone.down.waves.left.and.right"
        case .notifications: "bell.badge"
        case .settings: "gearshape.fill"
        }
    }

    var title: String {
        switch self {
        case .call: "Call"
        case .notifications: "Notifications"
        case .settings: "Settings"
        }
    }
}

struct SFSymbolAnimatedTabBarDemoView: View {
    @State private var selectedTab: AppTab = .call
    var body: some View {
        AnimatedSFSymbolTabView(selected: $selectedTab) {
            Tab(AppTab.call.title, systemImage: AppTab.call.symbolImage, value: .call) {
                Text("Call")
            }

            Tab(AppTab.notifications.title, systemImage: AppTab.notifications.symbolImage, value: .notifications) {
                Text("Notiifications")
            }

            Tab(AppTab.settings.title, systemImage: AppTab.settings.symbolImage, value: .settings) {
                Text("Settings")
            }
        } effects: { tab in
            switch tab {
            case .call: [.bounce.up]
            case .notifications: [.wiggle]
            case .settings: [.rotate]
            }
        }
    }
}

#Preview {
    SFSymbolAnimatedTabBarDemoView()
}
