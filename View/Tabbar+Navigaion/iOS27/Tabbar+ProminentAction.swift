//
//  Tabbar+ProminentAction.swift
//  animation
//
//  Created on 8/16/26.
import SwiftUI

@available(iOS 27.0, *)
struct ProminentActionTabBarDemo: View {
    @State private var showTabView: Bool = true
    @State private var activeTab: TabiOS17 = .photos
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $activeTab) {
                Tab(value: .photos) {
                    Text("Photos")
                        .toolbarVisibility(.hidden, for: .tabBar)
                }

                Tab(value: .chat) {
                    Text("Messages")
                        .toolbarVisibility(.hidden, for: .tabBar)
                }

                Tab(value: .profile) {
                    Text("Profiles")
                        .toolbarVisibility(.hidden, for: .tabBar)
                }
            }

            ProminentTabBar(selection: $activeTab, prominentSymbol: "plus") {
                Text("Hello World")
                    .frame(width: 250, height: 350)
            }
        }
    }
}

private protocol ProminentTabItem: CaseIterable, Hashable {
    var symbol: String { get }
    var title: String { get }
}

extension TabiOS17: ProminentTabItem {
    var symbol: String {
        rawValue
    }
}

@available(iOS 27.0, *)
private struct ProminentTabBar<Item: ProminentTabItem, PopoverContent: View>: View {
    @Binding var selection: Item
    var prominentSymbol: String
    @ContentBuilder var popover: PopoverContent
    /// View properties
    @State private var showPopover: Bool = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Namespace private var namespace

    var body: some View {
        let tabCount = Item.allCases.count
        let isSmall = tabCount <= 2 || horizontalSizeClass == .regular

        GlassEffectContainer(spacing: 10) {
            HStack(spacing: 10) {
                CustomProminentTabBar(selection: $selection)
                    .padding(2)
                    .glassEffect(.regular.interactive(), in: .capsule)
                    .frame(width: isSmall ? CGFloat(tabCount) * 90 : nil)
                    .frame(maxWidth: .infinity, alignment: isSmall ? .leading : .center)

                Button {
                    showPopover = true
                } label: {
                    Image(systemName: prominentSymbol)
                        .font(.title)
                        .scaleEffect(0.95)
                        .frame(width: 40, height: 50)
                        .matchedTransitionSource(id: "POPOVER", in: namespace)
                }
                .buttonStyle(.glass)
                .popover(isPresented: $showPopover) {
                    popover
                        .presentationCompactAdaptation(.popover)
                        .navigationTransition(.zoom(sourceID: "POPOVER", in: namespace))
                }
            }
        }
        .padding([.bottom, .horizontal], 25)
        .ignoresSafeArea(.all, edges: .bottom)
    }
}

private struct CustomProminentTabBar<Item: ProminentTabItem>: UIViewRepresentable {
    @Binding var selection: Item
    @Environment(\.displayScale) private var displayScale

    func makeUIView(context: Context) -> UISegmentedControl {
        let control = UISegmentedControl(items: allTabs.compactMap { generateItemImage($0) })
        control.selectedSegmentIndex = allTabs.firstIndex(of: selection) ?? 0
        control.selectedSegmentTintColor = UIColor(Color.gray.opacity(0.18))
        control.addTarget(
            context.coordinator,
            action: #selector(context.coordinator.didChange(_:)),
            for: .valueChanged
        )
        /// Removing background
        DispatchQueue.main.async {
            for subview in control.subviews {
                if subview is UIImageView, subview != control.subviews.last {
                    subview.alpha = 0
                }
            }
        }
        return control
    }

    func updateUIView(_ uiView: UISegmentedControl, context _: Context) {
        if let selectionIndex = allTabs.firstIndex(of: selection), uiView.selectedSegmentIndex != selectionIndex {
            uiView.selectedSegmentIndex = selectionIndex
        }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView _: UISegmentedControl, context _: Context) -> CGSize? {
        .init(width: proposal.replacingUnspecifiedDimensions().width, height: 60)
    }

    /// limit to 4 items due to limited tab bar width
    private var allTabs: [Item] {
        Array(Item.allCases.prefix(3))
    }

    private func generateItemImage(_ item: Item) -> UIImage? {
        let renderer = ImageRenderer(content: VStack(spacing: 4) {
            Image(systemName: item.symbol)
                .font(.title3)
                .fontWeight(.regular)
                .symbolVariant(.fill)
                .frame(height: 25)

            Text(item.title)
                .font(.caption2)

        })
        renderer.scale = displayScale
        return renderer.uiImage
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(selection: $selection)
    }

    class Coordinator: NSObject {
        @Binding var selection: Item
        init(selection: Binding<Item>) {
            _selection = selection
        }

        @objc func didChange(_ control: UISegmentedControl) {
            selection = Array(Item.allCases)[control.selectedSegmentIndex]
        }
    }
}

@available(iOS 27.0, *)
#Preview {
    ProminentActionTabBarDemo()
}
