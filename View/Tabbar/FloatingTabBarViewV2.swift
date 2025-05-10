//
// support both iOS 17 & 18
// different way to hide tabbar

import SwiftUI

struct FloatingTabV2DemoView: View {
    /// View Properties
    @State private var activeTab: VideoTab = .home
    var body: some View {
        FloatingTabBarV2View(selection: $activeTab) { tab, tabBarHeight in
            switch tab {
            case .home: Text(tab.rawValue)
            case .shorts: RadisView(tabBarHeight: tabBarHeight)
            case .progress: Text(tab.rawValue)
            case .carousel: Text(tab.rawValue)
            case .profile: Text(tab.rawValue)
            }
        }
    }
}

struct RadisView: View {
    var tabBarHeight: CGFloat
    @State private var hideTabBar: Bool = false
    var body: some View {
        NavigationStack {
            VStack {
                Spacer(minLength: 0)
                Button("Hide/Show Tab Bar") {
                    hideTabBar.toggle()
                }
            }
            .padding()
            .navigationTitle("Toggle Tab Bar")
            .safeAreaPadding(.bottom, tabBarHeight)
        }
        .hideFloatingTabBar(hideTabBar)
    }
}

private struct FloatingTabBar<Value: CaseIterable & Hashable & FloatingTabProtocol>: View where
    Value.AllCases: RandomAccessCollection
{
    var config: FloatingTabBarViewV2Config
    @Binding var activeTab: Value
    /// For tab sliding effect
    @Namespace private var animation
    /// For Symbol effect
    @State private var toggleSymbolEffect: [Bool] = Array(repeating: false, count: Value.allCases.count)

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Value.allCases, id: \.hashValue) { tab in
                let isActive = activeTab == tab
                let index = (Value.allCases.firstIndex(of: tab) as? Int) ?? 0

                Image(systemName: tab.symbolImage)
                    .font(.title3)
                    .foregroundStyle(isActive ? config.activeTint : config.inactiveTint)
                    .symbolEffect(.bounce.byLayer.down, value: toggleSymbolEffect[index])
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(.rect)
                    .background {
                        if isActive {
                            Capsule(style: .continuous)
                                .fill(config.activeBackgroundTint.gradient)
                                .matchedGeometryEffect(id: "ACTIVETAB", in: animation)
                        }
                    }
                    .onTapGesture {
                        activeTab = tab
                        toggleSymbolEffect[index].toggle()
                    }
                    .padding(.vertical, config.insetAmount)
            }
        }
        .padding(.horizontal, config.insetAmount)
        .frame(height: 50)
        .background {
            ZStack {
                if config.isTranslucent {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                } else {
                    Rectangle()
                        .fill(.background)
                }

                Rectangle()
                    .fill(config.backgroundColor)
            }
        }
        .clipShape(Capsule())
        .animation(config.tabAnimation, value: activeTab)
    }
}

struct FloatingTabBarV2View<Content: View, Value: CaseIterable & Hashable & FloatingTabProtocol>: View
    where Value.AllCases: RandomAccessCollection
{
    var config: FloatingTabBarViewV2Config
    @Binding var selection: Value
    // get the height of the floating tab bar
    var content: (Value, CGFloat) -> Content

    init(config: FloatingTabBarViewV2Config = .init(),
         selection: Binding<Value>,
         @ViewBuilder content: @escaping (Value, CGFloat) -> Content)
    {
        self.config = config
        _selection = selection
        self.content = content
    }

    @State private var tabBarSize: CGSize = .zero
    @StateObject private var helper: FloatingTabBarViewV2Helper = .init()

    var body: some View {
        ZStack(alignment: .bottom) {
            if #available(iOS 18, *) {
                TabView(selection: $selection) {
                    ForEach(Value.allCases, id: \.hashValue) { tab in
                        Tab(value: tab) {
                            content(tab, tabBarSize.height)
                                .toolbarVisibility(.hidden, for: .tabBar)
                        }
                    }
                }
            } else {
                TabView(selection: $selection) {
                    ForEach(Value.allCases, id: \.hashValue) { tab in
                        content(tab, tabBarSize.height)
                            .tag(tab) /// old tag type of tab view
                            .toolbarVisibility(.hidden, for: .tabBar)
                    }
                }
            }

            FloatingTabBar(config: config, activeTab: $selection)
                .padding(.horizontal, config.hPadding)
                .padding(.bottom, config.vPadding)
                .onGeometryChange(for: CGSize.self) {
                    $0.size
                } action: { newValue in
                    tabBarSize = newValue
                }
                .offset(y: helper.hideTabBar ? (tabBarSize.height + 100) : 0)
                .animation(config.tabAnimation, value: helper.hideTabBar)
        }
        .environmentObject(helper)
    }
}

extension VideoTab: FloatingTabProtocol {
    var symbolImage: String {
        switch self {
        case .home:
            "house.fill"
        case .shorts:
            "video.badge.waveform.fill"
        case .profile:
            "play.square.stack.fill"
        case .carousel:
            "person.circle.fill"
        case .progress:
            "person.2.crop.square.stack.fill"
        }
    }
}

private extension View {
    func hideFloatingTabBar(_ status: Bool) -> some View {
        modifier(HideFloatingTabBarModifier(status: status))
    }
}

struct FloatingTabBarViewV2Config {
    var activeTint: Color = .white
    var activeBackgroundTint: Color = .blue
    var inactiveTint: Color = .gray
    var tabAnimation: Animation = .smooth(duration: 0.35, extraBounce: 0)
    var backgroundColor: Color = .gray.opacity(0.1)
    var insetAmount: CGFloat = 6
    var isTranslucent: Bool = true
    var hPadding: CGFloat = 15
    var vPadding: CGFloat = 5
}

protocol FloatingTabProtocol {
    var symbolImage: String { get }
}

private class FloatingTabBarViewV2Helper: ObservableObject {
    @Published var hideTabBar: Bool = false
}

private struct HideFloatingTabBarModifier: ViewModifier {
    var status: Bool
    @EnvironmentObject private var helper: FloatingTabBarViewV2Helper
    func body(content: Content) -> some View {
        content
            .onChange(of: status, initial: true) { _, newValue in
                helper.hideTabBar = newValue
            }
    }
}

#Preview {
    FloatingTabV2DemoView()
}
