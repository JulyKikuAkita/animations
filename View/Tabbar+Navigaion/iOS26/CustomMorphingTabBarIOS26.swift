//
//  CustomMorphingTabBarIOS26.swift
//  animation
//
//  Created on 2/11/26.
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

            MorphingTabBar(activeTab: $activeTab, isExpanded: $isExpanded) {}
                .padding(.horizontal, 20)
                .padding(.bottom, 25)
        }
        .ignoresSafeArea(.all, edges: .bottom)
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
                ) {} label: {
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
