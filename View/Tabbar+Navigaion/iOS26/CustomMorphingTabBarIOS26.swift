//
//  CustomMorphingTabBarIOS26.swift
//  animation
//
//  Learning point
//  ──────────────
//  A glass tab bar paired with a "+" floating action button that EXPANDS
//  into a 4-column grid of quick actions (think Apple Music / iMovie
//  edit menus). Tapping "+" toggles `isExpanded`; the whole grid morphs
//  out of the same liquid-glass surface as the tab bar.
//
//  Key APIs
//  ────────
//  • `ExpandableGlassMenuContainer` (custom) — the project's helper that
//    drives the open/close progress and re-shapes the container.
//  • `GlassEffectContainer` — wraps the action grid so each button shares
//    one glass pass and morphs together.
//  • `.glassEffect(.regular.interactive(), in:)` — per-button glass with
//    touch-following highlight; reused in `PlanGlassButtonEffect`.
//  • `UIViewRepresentable` over `UISegmentedControl` — same UIKit-bridge
//    pattern as the other morph demos, generic over any `MorphingTabProtocol`.
//  • `withAnimation(.bouncy(duration:extraBounce:))` — drives the FAB toggle.
//
//  How to apply
//  ────────────
//  Use when you need a quick-action surface anchored to the tab bar
//  WITHOUT replacing the tab bar (the bar stays usable while expanded).
//  Good for editor / compose flows that need 4–12 secondary actions.
//
//  See also
//  ────────
//  • CustomMorphingTab+BottomBar+IOS26.swift — the other glass-morph
//    variant: same UISegmentedControl bridge, but morphs by NAV DEPTH
//    rather than by an explicit FAB tap.
//  • iOS26+customSearch+FAB+Tabbar.swift — a third FAB style that lives
//    INSIDE the system tab bar via `Tab(role: .search)`.
//
import SwiftUI

private enum MorphTabTab: String, MorphingTabProtocol {
    case home = "Home"
    case search = "Search"
    case profile = "Profile"
    case settings = "Settings"

    var symbolImage: String {
        switch self {
        case .home: "house.fill"
        case .search: "magnifyingglass"
        case .profile: "person.fill"
        case .settings: "gearshape.fill"
        }
    }
}

@available(iOS 26.0, *)
struct CustomMorphingTabBarIOS26DemoView: View {
    @State private var activeTab: MorphTabTab = .home
    @State private var isExpanded: Bool = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Rectangle()
                .foregroundStyle(.clear)
                .overlay {
                    Text(activeTab.rawValue)
                }
            HStack(alignment: .bottom, spacing: 12) {
                MorphingTabBar(activeTab: $activeTab, isExpanded: $isExpanded) {
                    dummyExpandedContent()
                }
                Button {
                    withAnimation(.bouncy(duration: 0.5, extraBounce: 0.05)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 19, weight: .medium))
                        .frame(width: 52, height: 52)
                        .foregroundStyle(.primary)
                }
                .buttonStyle(PlanGlassButtonEffect(shape: .circle))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 25)
        }
        .ignoresSafeArea(.all, edges: .bottom)
    }

    func dummyExpandedContent() -> some View {
        GlassEffectContainer(spacing: 10) {
            LazyVGrid(columns: Array(repeating: GridItem(spacing: 10), count: 4), spacing: 10) {
                ForEach(iconActions) { action in
                    VStack(spacing: 6) {
                        Button {} label: {
                            Image(systemName: action.icon)
                                .font(.title3)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .foregroundStyle(.primary)
                                .background(.gray.opacity(0.09), in: .rect(cornerRadius: 16))
                        }
                        .buttonStyle(PlanGlassButtonEffect(shape: .rect(cornerRadius: 16)))

                        Text(action.title)
                            .font(.system(size: 9))
                    }
                }
            }
        }
        .padding(20)
    }
}

@available(iOS 26.0, *)
struct PlanGlassButtonEffect<S: Shape>: ButtonStyle {
    var shape: S
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .glassEffect(.regular.interactive(), in: shape)
    }
}

protocol MorphingTabProtocol: CaseIterable, Hashable {
    var symbolImage: String { get }
}

@available(iOS 26.0, *)
struct MorphingTabBar<Tab: MorphingTabProtocol, ExpandedContent: View>: View {
    @Binding var activeTab: Tab
    @Binding var isExpanded: Bool
    @ViewBuilder var expandedContent: ExpandedContent
    /// View Properties
    @State private var viewWidth: CGFloat?
    var body: some View {
        ZStack {
            let symbols = Array(Tab.allCases).compactMap(\.symbolImage)
            let selectedIndex = Binding {
                symbols.firstIndex(of: activeTab.symbolImage) ?? 0
            } set: { index in
                activeTab = Array(Tab.allCases)[index]
            }

            if let viewWidth {
                let progress: CGFloat = isExpanded ? 1 : 0
                let labelSize = CGSize(width: viewWidth, height: 52)
                let cornerRadius: CGFloat = labelSize.height / 2
                ExpandableGlassMenuContainer(
                    alignment: .center,
                    progress: progress,
                    labelSize: labelSize,
                    cornerRadius: cornerRadius
                ) {
                    expandedContent
                } label: {
                    CustomMorphingTabBarIOS26(
                        symbols: symbols,
                        index: selectedIndex
                    ) { image in
                        let font = UIFont.systemFont(ofSize: 19)
                        let configuration = UIImage.SymbolConfiguration(font: font)

                        return UIImage(systemName: image, withConfiguration: configuration)
                    }
                    .frame(height: 48)
                    .padding(.horizontal, 2)
                    .offset(y: -0.7)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .onGeometryChange(for: CGFloat.self) {
            $0.size.width
        } action: { newValue in
            viewWidth = newValue
        }
        .frame(height: viewWidth == nil ? 52 : nil)
    }
}

private struct CustomMorphingTabBarIOS26: UIViewRepresentable {
    var tint: Color = .gray.opacity(0.15)
    var symbols: [String]
    @Binding var index: Int
    var image: (String) -> UIImage?

    func makeUIView(context: Context) -> UISegmentedControl {
        let control = UISegmentedControl(items: symbols)
        control.selectedSegmentIndex = index
        control.selectedSegmentTintColor = UIColor(tint)
        for (index, symbol) in symbols.enumerated() {
            control.setImage(image(symbol), forSegmentAt: index)
        }

        control.addTarget(context.coordinator, action: #selector(context.coordinator.didSelect(_:)),
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
        if uiView.selectedSegmentIndex != index {
            uiView.selectedSegmentIndex = index
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject {
        var parent: CustomMorphingTabBarIOS26
        init(parent: CustomMorphingTabBarIOS26) {
            self.parent = parent
        }

        @MainActor @objc
        func didSelect(_ control: UISegmentedControl) {
            parent.index = control.selectedSegmentIndex
        }
    }

    /// Free size
    func sizeThatFits(_ proposal: ProposedViewSize, uiView _: UISegmentedControl, context _: Context) -> CGSize? {
        proposal.replacingUnspecifiedDimensions()
    }
}

@available(iOS 26.0, *)
#Preview {
    CustomMorphingTabBarIOS26DemoView()
}

private struct IconAction: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
}

private let iconActions: [IconAction] = [
    IconAction(icon: "scissors", title: "Trim"),
    IconAction(icon: "crop", title: "Crop"),
    IconAction(icon: "wand.and.stars", title: "Enhance"),
    IconAction(icon: "textformat", title: "Text"),
    IconAction(icon: "music.note", title: "Audio"),
    IconAction(icon: "hare", title: "Speed"),
    IconAction(icon: "square.on.square", title: "Duplicate"),
    IconAction(icon: "arrow.uturn.backward", title: "Undo"),
    IconAction(icon: "square.and.arrow.up", title: "Share"),
    IconAction(icon: "bookmark", title: "Save"),
    IconAction(icon: "trash", title: "Delete"),
]
