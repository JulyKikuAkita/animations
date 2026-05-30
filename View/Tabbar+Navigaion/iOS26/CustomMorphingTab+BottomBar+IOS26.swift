//
//  CustomMorphingTab+BottomBar+IOS26.swift
//  animation
//
//  Learning point
//  ──────────────
//  A single bottom bar that morphs between TWO ROLES depending on
//  navigation depth: at the tab root it acts as a segmented tab selector;
//  once a detail is pushed onto the NavigationStack it reshapes into a
//  contextual action bar (main action + optional leading/trailing actions).
//  The whole transition is driven by flipping ONE Bool inside a shared
//  `Config` struct.
//
//  Key APIs
//  ────────
//  • `GlassEffectContainer` — groups iOS 26 liquid-glass shapes so they
//    blend / morph together instead of fading independently.
//  • `AnyLayout` (HStack ↔ ZStack swap) — drives the layout change without
//    if/else branches that would re-identify the views and break animation.
//  • `.glassEffect(_:in:)` with `.interactive(_:)` — toggled per-state so
//    the highlight only follows touch when the bar is in action mode.
//  • `UIViewRepresentable` over `UISegmentedControl` — used for the tab
//    selector so we get the system's segmented control look-and-feel.
//  • `.toolbarVisibility(.hidden, for: .tabBar)` per Tab — hides the
//    system tab bar so the custom one can float in its place.
//
//  How to apply
//  ────────────
//  Reach for this when ONE bar must serve different jobs in different
//  app states (root vs detail, idle vs editing, viewer vs composer).
//  Keep state in a single source of truth and let SwiftUI animate the
//  diff; resist branching the bar into two separate views.
//
//  See also
//  ────────
//  • CustomMorphingTabBarIOS26.swift — the OTHER glass-morph variant:
//    instead of swapping roles, it expands into a 4-column action grid
//    (Apple-Music–style FAB).
//  • iOS26+customSearch+FAB+Tabbar.swift — yet another FAB pattern that
//    hijacks `Tab(role: .search)` instead of using a custom bar.
//
import SwiftUI

#if os(iOS)

    @available(iOS 26.0, *)
    struct FlexMorphingTabAndBottomBarIOS26DemoView: View {
        @State private var tabConfig: FlexMorphingTabAndBottomBarIOS26.Config = .init(activeTab: 0)
        var body: some View {
            // Bottom-aligned ZStack lets the custom bar sit where the system tab bar would,
            // which is why every Tab below must hide the native one.
            ZStack(alignment: .bottom) {
                TabView(selection: $tabConfig.activeTab) {
                    Tab(value: 0) {
                        DemoHomeNestedView(config: $tabConfig)
                            .toolbarVisibility(.hidden, for: .tabBar)
                    }
                    Tab(value: 1) { Text("Pet").toolbarVisibility(.hidden, for: .tabBar) }
                    Tab(value: 2) { Text("Account").toolbarVisibility(.hidden, for: .tabBar) }
                }
                // Symbols here mirror the tab order driven by `tabConfig.activeTab`.
                FlexMorphingTabAndBottomBarIOS26(tabs: [
                    .init(symbol: "house.fill"),
                    .init(symbol: "pawprint.fill"),
                    .init(symbol: "person.fill"),
                ], config: $tabConfig)
            }
        }
    }

    @available(iOS 26.0, *)
    private struct DemoHomeNestedView: View {
        @Binding var config: FlexMorphingTabAndBottomBarIOS26.Config
        /// View Properties
        @State private var navigationPath: NavigationPath = .init()
        var body: some View {
            NavigationStack(path: $navigationPath) {
                ScrollView(.vertical) {
                    LazyVGrid(columns: Array(repeating: GridItem(), count: 3)) {
                        ForEach(dummyBeamColors, id: \.self) { color in
                            DummyRectangles(color: color, count: 1, height: 90)
                                .onTapGesture {
                                    navigationPath.append(color)
                                }
                        }
                    }
                }
                .safeAreaPadding(15)
                .navigationTitle("Photos")
                .navigationDestination(for: Color.self) { color in
                    DummyRectangles(color: color, count: 1, height: 400)
                        .frame(width: 300)
                        .navigationTitle(String(describing: color).capitalized)
                }
            }
            .onChange(of: navigationPath) { _, _ in
                let mainAction: FlexMorphingTabAndBottomBarIOS26.ActionItem = .init(
                    symbol: "suit.heart.fill") {}
                let leadingAction: FlexMorphingTabAndBottomBarIOS26.ActionItem = .init(
                    symbol: "hand.thumbsup") {}
                let trailingAction: FlexMorphingTabAndBottomBarIOS26.ActionItem = .init(
                    symbol: "hand.thumbsdown") {}

                config.flexibility = .fixed
                config.tabActions = .init(
                    mainActionShape: .circle,
                    mainAction: mainAction,
                    leadingAction: leadingAction,
                    trailingAction: trailingAction
                )
                Task {
                    config.isMorphed = !navigationPath.isEmpty
                }
            }
        }
    }

    @available(iOS 26.0, *)
    struct FlexMorphingTabAndBottomBarIOS26: View {
        var tabs: [TabItem]
        @Binding var config: Config
        /// View properties
        @State private var isGlassInteractionEnabled: Bool = false
        var body: some View {
            GlassEffectContainer(spacing: 10) {
                let isMorphed = config.isMorphed
                let tabActions = config.tabActions
                let mainActionShape = tabActions?.mainActionShape ?? .capsule
                let mainBackgroundColor = tabActions?.mainActionBackground ?? .clear
                let layout = isMorphed ? AnyLayout(HStackLayout(spacing: 10)) : AnyLayout(ZStackLayout())

                layout {
                    if let leadingAction = tabActions?.leadingAction {
                        actionItemView(leadingAction)
                        if config.flexibility == .flexible {
                            Spacer(minLength: 0)
                        }
                    }

                    let morphWidth: CGFloat = mainActionShape == .capsule ? 110 : 45
                    let morphHeight: CGFloat = mainActionShape == .capsule ? 50 : 45
                    /// Each tab width: 60
                    FlexMorphingIOS26Helper(tabs: tabs, activeTab: $config.activeTab)
                        .opacity(isMorphed ? 0 : 1)
                        .allowsHitTesting(!isMorphed)
                        .frame(width: CGFloat(tabs.count) * 60, height: 45)
                        .frame(width: isMorphed ? morphWidth : nil, height: isMorphed ? morphHeight : nil)
                        .overlay {
                            if let mainAction = tabActions?.mainAction {
                                Image(systemName: mainAction.symbol)
                                    .font(mainActionShape == .circle ? .title3 : .title2)
                                    .fontWeight(.medium)
                                    .foregroundStyle(tabActions?.mainActionForeground ?? .primary)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .contentShape(.capsule)
                                    .onTapGesture { mainAction.action() }
                                    .opacity(isMorphed ? 1 : 0)
                                    .blur(radius: isMorphed ? 0 : 6)
                                    .allowsHitTesting(isMorphed)
                            }
                        }
                        .clipShape(.capsule)
                        .glassEffect(
                            .regular
                                .tint(mainBackgroundColor.opacity(isMorphed ? 1 : 0))
                                .interactive(isGlassInteractionEnabled),
                            in: .capsule
                        )

                    if let trailingAction = tabActions?.trailingAction {
                        if config.flexibility == .flexible {
                            Spacer(minLength: 0)
                        }
                        actionItemView(trailingAction)
                    }
                }
            }
            .animation(config.morphAnimation, value: config.isMorphed)
            .onChange(of: config.isMorphed) { _, _ in
                isGlassInteractionEnabled = false
                DispatchQueue.main.async {
                    isGlassInteractionEnabled = true
                }
            }
            .padding(.horizontal, 15)
        }

        private func actionItemView(_ item: ActionItem) -> some View {
            ZStack {
                if config.isMorphed {
                    Image(systemName: item.symbol)
                        .font(.title3)
                        .foregroundStyle(.primary)
                        .transition(.blurReplace.combined(with: .opacity))
                }
            }
            .frame(width: 45, height: 45)
            .contentShape(.circle)
            .glassEffect(.regular.interactive(config.isMorphed), in: .circle)
            .onTapGesture { item.action() }
            .allowsHitTesting(config.isMorphed)
        }

        struct Config {
            var activeTab: Int
            var flexibility: Flexibility = .fixed
            var isMorphed: Bool = false
            var tabActions: TabActions?
            var morphAnimation: Animation = .smooth
        }

        struct TabItem {
            var symbol: String
        }

        struct TabActions {
            var mainActionShape: MainActionShape = .capsule
            var mainActionForeground: Color = .white
            var mainActionBackground: Color = .red
            var mainAction: ActionItem
            var leadingAction: ActionItem?
            var trailingAction: ActionItem?
        }

        struct ActionItem {
            var symbol: String
            var action: () -> Void
        }

        enum Flexibility: String, CaseIterable {
            case fixed = "Fixed"
            case flexible = "Flexible"
        }

        enum MainActionShape: String, CaseIterable {
            case circle = "Circle"
            case capsule = "Capsule"
        }
    }

    /// Customize  segmented control for flexibility
    @available(iOS 26.0, *)
    private struct FlexMorphingIOS26Helper: UIViewRepresentable {
        var tabs: [FlexMorphingTabAndBottomBarIOS26.TabItem]
        @Binding var activeTab: Int

        func makeUIView(context: Context) -> UISegmentedControl {
            let control = UISegmentedControl(items: tabs.compactMap(\.symbol))
            let font = UIFont.preferredFont(forTextStyle: .body)

            for (index, item) in tabs.enumerated() {
                let image = UIImage(systemName: item.symbol,
                                    withConfiguration: UIImage.SymbolConfiguration(font: font))
                control.setImage(image, forSegmentAt: index)
            }
            control.selectedSegmentTintColor = UIColor(Color.gray.opacity(0.25))
            control.addTarget(context.coordinator, action: #selector(Coordinator.didItemChanged(_:)),
                              for: .valueChanged)

            /// Removing background color
            DispatchQueue.main.async {
                for view in control.subviews.dropLast() {
                    if view is UIImageView {
                        view.alpha = 0
                    }
                }
            }
            return control
        }

        func updateUIView(_ uiView: UISegmentedControl, context _: Context) {
            if uiView.selectedSegmentIndex != activeTab {
                uiView.selectedSegmentIndex = activeTab
            }
        }

        func makeCoordinator() -> Coordinator {
            Coordinator(parent: self)
        }

        class Coordinator: NSObject {
            var parent: FlexMorphingIOS26Helper
            init(parent: FlexMorphingIOS26Helper) {
                self.parent = parent
            }

            @MainActor @objc
            func didItemChanged(_ control: UISegmentedControl) {
                parent.activeTab = control.selectedSegmentIndex
            }
        }

        /// Free size
        func sizeThatFits(_ proposal: ProposedViewSize, uiView _: UISegmentedControl, context _: Context) -> CGSize? {
            .init(width: proposal.width ?? 0, height: proposal.height ?? 0)
        }
    }

    @available(iOS 26.0, *)
    #Preview {
        FlexMorphingTabAndBottomBarIOS26DemoView()
    }

#endif
