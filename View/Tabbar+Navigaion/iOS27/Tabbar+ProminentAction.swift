//
//  Tabbar+ProminentAction.swift
//  animation
//
//  Created on 8/16/26.
//
//  Learning point
//  ──────────────
//  A bottom bar split into two glass surfaces: a segmented tab bar plus a
//  detached "prominent action" (+) button that opens a popover. The stock
//  `TabView` bar is hidden per tab, so `TabView` keeps doing selection and
//  content hosting while the visible bar is entirely hand-rolled — and the
//  bar itself is a UIKit `UISegmentedControl`, not SwiftUI buttons.
//
//  Why reach for UIKit here: `UISegmentedControl` already ships the parts
//  that are tedious to rebuild — an indicator that slides between segments,
//  and a drag that carries the selection with the finger. The cost is that
//  segments accept only text or `UIImage`, which is what forces the
//  `ImageRenderer` step in step 2 below.
//
//  Mechanics
//  ─────────
//    1. Each `Tab`'s content hides the system bar with
//       `.toolbarVisibility(.hidden, for: .tabBar)`, and a
//       `ZStack(alignment: .bottom)` layers the custom bar over the `TabView`.
//    2. `CustomProminentTabBar` wraps `UISegmentedControl`; every segment
//       image is a SwiftUI `VStack` (symbol over caption) rasterized by
//       `ImageRenderer`.
//    3. Selection is two-way: `.valueChanged` → `Coordinator` → binding
//       (UIKit → SwiftUI), and `updateUIView` → `selectedSegmentIndex`
//       (SwiftUI → UIKit).
//    4. The bar and the + button share one `GlassEffectContainer`, so their
//       glass reads as a single material rather than two separate stickers.
//    5. The + button is a zoom transition source, so the popover appears to
//       grow out of the button.
//
//  Key APIs
//  ────────
//  • `.toolbarVisibility(.hidden, for: .tabBar)` — keep `TabView`, drop its bar.
//  • `UIViewRepresentable` + `sizeThatFits` — host UIKit and report the size
//    it wants back to SwiftUI layout.
//  • `ImageRenderer` (+ `\.displayScale`) — SwiftUI view → `UIImage`, for
//    UIKit APIs that only accept images.
//  • `GlassEffectContainer` / `.glassEffect(.regular.interactive(), in:)` /
//    `.buttonStyle(.glass)` — Liquid Glass in one shared pass.
//  • `.matchedTransitionSource(id:in:)` + `.navigationTransition(.zoom(sourceID:in:))`
//    — the paired source/destination zoom.
//  • `.presentationCompactAdaptation(.popover)` — stay a popover at compact
//    width instead of adapting into a sheet.
//
//  Trade-offs to stay clear-eyed about
//  ───────────────────────────────────
//  • Hiding the segmented control's own background reaches into its private
//    subviews (see `makeUIView`). Unlike the sibling demo below, there is no
//    failure path: if that hierarchy changes, the bar just looks wrong.
//  • Segment images are bitmaps built once in `makeUIView`, so Dynamic Type
//    and appearance changes are never picked up. Production code would
//    re-render them when the relevant traits change.
//  • The custom bar adds no safe-area inset, so scrolling content would run
//    underneath it. Host it with `safeAreaInset(edge: .bottom)` once the tabs
//    hold real scroll views.
//
//  How to apply
//  ────────────
//  Reach for this shape when the primary action belongs outside the tab set
//  (compose, capture, add) and the tabs themselves should stay a compact
//  segmented pill. Swap `TabiOS17` for any `ProminentTabItem` enum.
//
//  Note: `@ContentBuilder` is the project's result builder; swap to
//  `@ViewBuilder` on stock Xcode 26.
//
//  See also
//  ────────
//  • HScrollToMinimizeTabbar.swift — sibling iOS27 demo that recovers tab bar
//    state from UIKit, with an explicit failure path for the same class of
//    private-hierarchy walk.
//
import SwiftUI

@available(iOS 27.0, *)
struct ProminentActionTabBarDemo: View {
    @State private var showTabView: Bool = true
    @State private var activeTab: TabiOS17 = .photos
    var body: some View {
        /// The `TabView` keeps hosting content and owning selection; only its bar is replaced.
        /// The custom bar is layered on top rather than injected, so it never participates in
        /// the `TabView`'s own layout.
        ZStack(alignment: .bottom) {
            TabView(selection: $activeTab) {
                /// `CustomProminentTabBar` renders `Item.allCases.prefix(3)` — see `allTabs` —
                /// so the declared tab values have to cover that prefix. A segment whose value
                /// has no `Tab` here selects nothing.
                Tab(value: .photos) {
                    Text("Photos")
                        /// Hiding is per tab content, not on the `TabView`: the modifier travels
                        /// from the content out to the bar hosting it, so any tab that omits it
                        /// brings the system bar back for that tab alone.
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

/// The bar is written against this rather than against `TabiOS17`, so any tab enum can drive it.
///
/// `CaseIterable` supplies the segment list and `Hashable` the index lookup. Declaring the
/// protocol `private` keeps the conformance below file-local, so nothing outside this demo can
/// accidentally depend on it.
private protocol ProminentTabItem: CaseIterable, Hashable {
    var symbol: String { get }
    var title: String { get }
}

/// `TabiOS17` stores SF Symbol names as its raw values and already provides `title`, so the
/// conformance is a single line.
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

        /// One container around both surfaces, so the bar and the button blend as a single
        /// material once they come within `spacing` of each other instead of rendering as two
        /// unrelated glass shapes.
        GlassEffectContainer(spacing: 10) {
            HStack(spacing: 10) {
                CustomProminentTabBar(selection: $selection)
                    .padding(2)
                    .glassEffect(.regular.interactive(), in: .capsule)
                    /// A full-width bar would stretch across a regular-width window, so there
                    /// the width is pinned to a per-segment budget and pushed to the leading
                    /// edge. Note the budget counts *all* cases while the bar renders only
                    /// `allTabs`; the two have to move together.
                    .frame(width: isSmall ? CGFloat(tabCount) * 90 : nil)
                    .frame(maxWidth: .infinity, alignment: isSmall ? .leading : .center)

                Button {
                    showPopover = true
                } label: {
                    Image(systemName: prominentSymbol)
                        .font(.title)
                        .scaleEffect(0.95)
                        .frame(width: 40, height: 50)
                        /// Marks the geometry the zoom grows from. Both halves of the pair are
                        /// required — this source and the matching `sourceID` on the presented
                        /// content — or the presentation quietly uses its default transition.
                        .matchedTransitionSource(id: "POPOVER", in: namespace)
                }
                .buttonStyle(.glass)
                .popover(isPresented: $showPopover) {
                    popover
                        /// At compact width a popover would adapt into a sheet, which has no
                        /// anchor to zoom out of; forcing popover adaptation keeps the button as
                        /// the visual source.
                        .presentationCompactAdaptation(.popover)
                        .navigationTransition(.zoom(sourceID: "POPOVER", in: namespace))
                }
            }
        }
        /// The bar is allowed into the bottom safe area, so its distance from the screen edge
        /// comes from this padding rather than from the (tab-bar-less) inset.
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
        ///
        /// The control draws its own background and divider images, which would cover the glass
        /// capsule behind it. There is no API for that, so the private subview list is walked
        /// instead — deferred a run loop turn because those subviews do not exist yet at init.
        /// The last image view is spared: it is the selection indicator that
        /// `selectedSegmentTintColor` colors.
        ///
        /// Positional and undocumented, and it fails silently: a reordered hierarchy leaves the
        /// background showing rather than crashing.
        DispatchQueue.main.async {
            for subview in control.subviews {
                if subview is UIImageView, subview != control.subviews.last {
                    subview.alpha = 0
                }
            }
        }
        return control
    }

    /// Guarded because assigning `selectedSegmentIndex` restarts the indicator animation, so an
    /// unrelated update would cut a slide short mid-flight. Not loop protection — a programmatic
    /// assignment does not send `.valueChanged` back to the coordinator.
    func updateUIView(_ uiView: UISegmentedControl, context _: Context) {
        if let selectionIndex = allTabs.firstIndex(of: selection), uiView.selectedSegmentIndex != selectionIndex {
            uiView.selectedSegmentIndex = selectionIndex
        }
    }

    /// Height is stated outright: the control's intrinsic height is sized for text-only segments,
    /// well short of the symbol-over-caption images used here. Width just accepts what is
    /// offered — with the caveat that `replacingUnspecifiedDimensions()` resolves an unspecified
    /// proposal to 10pt, not to anything bar-shaped.
    func sizeThatFits(_ proposal: ProposedViewSize, uiView _: UISegmentedControl, context _: Context) -> CGSize? {
        .init(width: proposal.replacingUnspecifiedDimensions().width, height: 60)
    }

    /// Limited to 3 items: past that the captions truncate at compact width.
    ///
    /// This has to stay a *prefix*. `Coordinator.didChange` maps a segment index back through
    /// `Item.allCases`, which only lines up because the indices are shared — filtering or
    /// reordering here would resolve taps to the wrong tab.
    private var allTabs: [Item] {
        Array(Item.allCases.prefix(3))
    }

    /// `UISegmentedControl` takes text or `UIImage` per segment, so the SwiftUI item is
    /// rasterized to get a symbol above a caption. `scale` has to be set explicitly: the renderer
    /// defaults to 1.0 and would otherwise hand back a bitmap that looks soft on any retina
    /// display.
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

    /// The UIKit → SwiftUI half of the binding. It only needs the binding, not the representable:
    /// a `Binding` carries accessors into the state that owns it, so it keeps working after the
    /// struct that produced it has been replaced.
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
