//
//  ScrollToMinimizeTabbar.swift
//  animation
//
//  Created on 7/25/26.
//  Instagram App minimize-able tab bar

import SwiftUI

@available(iOS 26.0, *)
struct ScrollToMinimizeTabBarDemo: View {
    @State private var activeTab: InstaTab = .reels
    @State private var progress: CGFloat = 0

    var body: some View {
        TabView(selection: $activeTab) {
            Tab(value: .feed) {
                ScrollView(.vertical) {
                    Rectangle()
                        .foregroundStyle(.orange.opacity(0.1))
                        .frame(height: 2000)
                }
                .adoptForIGTabBar($progress)
                .hideToolbar(.tabBar)
            }

            Tab(value: .reels) {
                ScrollView(.vertical) {
                    Text("Tab Bar does't Resize")
                        .frame(maxWidth: .infinity)
                }
                .hideToolbar(.tabBar)
            }
            Tab(value: .messages) {
                ScrollView(.vertical) {
                    Text("Tab Bar does't Stay minimized")
                        .frame(maxWidth: .infinity)
                }
                .adoptForIGTabBar($progress)
                .hideToolbar(.tabBar)
            }
            Tab(value: .search) {
                Text("Search")
                    .hideToolbar(.tabBar)
            }
            Tab(value: .profile) {
                Text("Profile")
                    .hideToolbar(.tabBar)
            }
        }
        .overlay(alignment: .bottom) {
            IGStyleTabBar(selection: $activeTab) { tab in
                let config = UIImage.SymbolConfiguration(font: .systemFont(ofSize: 20))
                // "questionmark.circle" is a built-in SF Symbol, guaranteed non-nil fallback
                let fallback = UIImage(systemName: "questionmark.circle")!
                return UIImage(systemName: tab.symbolImage)?.withConfiguration(config) ?? fallback
            } onInteraction: {
                if progress != 0 {
                    withAnimation(.iSpring()) {
                        progress = 0
                    }
                }
            }
            .padding(4)
            .glassEffect(.regular.interactive(), in: .capsule)
            .scaleEffect(1 - (progress * 0.15), anchor: .bottom)
            .padding(.horizontal, 20)
        }
    }
}

@available(iOS 26.0, *)
#Preview {
    ScrollToMinimizeTabBarDemo()
}

/// Learning note — reusable UIKit-backed segmented tab bar, driven by any `CaseIterable & Hashable` enum.
/// - `selection`: bind to the same @State that drives the paired `TabView(selection:)`.
/// - `symbolImage`: maps each case to the `UIImage` shown in its segment (e.g. `InstaTab`, `VideoTab`, `AppleMusicTab`).
/// - `onInteraction`: fires on first touch, before the segment value changes — use to cancel other UI state
///   (e.g. un-minimize this bar) the instant the user touches it, rather than waiting for `valueChanged`.
/// UIKit types involved: `UIViewRepresentable` (SwiftUI↔UIKit bridge protocol), `UISegmentedControl`,
/// `UIImage`/`UIColor`, `NSObject` (Coordinator's superclass — required for `@objc`/`#selector` target-action),
/// and `UITouch`/`UIEvent` (touchesBegan params on `CustomSegmentControl` below).
struct IGStyleTabBar<Value: CaseIterable>: UIViewRepresentable where Value: Hashable {
    @Binding var selection: Value
    var symbolImage: (Value) -> UIImage
    var onInteraction: () -> Void

    func makeUIView(context: Context) -> CustomSegmentControl {
        let images = Array(Value.allCases).compactMap(symbolImage)
        let control = CustomSegmentControl(items: images)
        control.selectedSegmentIndex = Array(Value.allCases).firstIndex(of: selection) ?? 0
        control.selectedSegmentTintColor = UIColor(Color.gray.opacity(0.25))
        control.addTarget(
            context.coordinator, // must be the Coordinator (NSObject), not context.self, or valueChanged(_:) never fires
            action: #selector(context.coordinator.valueChanged(_:)),
            for: .valueChanged
        )
        control.onTouchBegin = onInteraction

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

    func updateUIView(_: CustomSegmentControl, context _: Context) {}

    /// custom sizing
    func sizeThatFits(_ proposal: ProposedViewSize, uiView _: CustomSegmentControl, context _: Context) -> CGSize? {
        .init(
            width: proposal.replacingUnspecifiedDimensions().width,
            height: 50
        )
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    // NSObject subclass required: UIKit target-action (#selector/addTarget) needs an Objective-C-visible object
    class Coordinator: NSObject {
        var parent: IGStyleTabBar
        init(parent: IGStyleTabBar) {
            self.parent = parent
        }

        @MainActor @objc func valueChanged(_ sender: UISegmentedControl) {
            parent.selection = Array(Value.allCases)[sender.selectedSegmentIndex]
        }
    }
}

// UIKit subclass: SwiftUI has no pre-tap touch hook, so override touchesBegan to catch the tap
// before selectedSegmentIndex changes and valueChanged fires.
class CustomSegmentControl: UISegmentedControl {
    var onTouchBegin: (() -> Void)?
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        onTouchBegin?()
    }
}

private extension ScrollView {
    @ContentBuilder
    @MainActor func adoptForIGTabBar(_ progress: Binding<CGFloat>) -> some View {
        modifier(IGTabBarViewModeManager(progress: progress))
    }
}

private struct IGTabBarViewModeManager: ViewModifier {
    /// 0: expanded, 1: minimized
    @Binding var progress: CGFloat
    /// View Properties
    @GestureState private var isDragging: Bool = false
    @State private var isScrolledUp: Bool?
    @State private var shiftOffset: CGFloat = 0
    @State private var scrollOffset: CGFloat = 0
    @State private var isLargerContent: Bool = false
    @State private var scrollPhase: ScrollPhase = .idle
    func body(content: Content) -> some View {
        content
            .hideToolbar(.tabBar)
            /// adjust tab bar height
            .safeAreaPadding(.bottom, 50)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(.rect)
            // simultaneousGesture (vs .gesture) lets this DragGesture run alongside ScrollView's own
            // recognizer instead of stealing it — .gesture() here would block scrolling entirely.
            .simultaneousGesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .scrollView)
                    .updating($isDragging) { _, state, _ in
                        state = true
                    }.onEnded { value in
                        guard scrollPhase != .idle else { return }

                        /// decrease velocity by increase 5 to different number
                        // negative height velocity = flung upward; flip sign so a bigger fling projects further
                        let velocity = -value.velocity.height / 5
                        // where the scroll would land if the fling continued past finger-lift
                        let resultOffset = scrollOffset + velocity
                        // same 0...1 normalization as the live onScrollGeometryChange handler below
                        let rawProgress = (resultOffset - shiftOffset) / distance
                        let clampedProgress = rawProgress.clamped(to: 0 ... 1)
                        withAnimation(.iSpring()) {
                            // snap fully open/closed past the midpoint, only when there's slack to scroll
                            progress = resultOffset > (distance / 2) && isLargerContent ? (
                                clampedProgress > 0.5 ? 1 : 0
                            ) : 0
                        }
                        isScrolledUp = nil
                        /// or any desired shiftOffset value
                        shiftOffset = scrollOffset - (progress * distance)
                    }
            )
            // tracks idle/tracking/decelerating so onEnded above can ignore drags that never actually scrolled
            .onScrollPhaseChange { _, newPhase in
                scrollPhase = newPhase
            }
            // scrollable slack (content taller than viewport) — the bar only minimizes when there's room to scroll
            .onScrollGeometryChange(for: CGFloat.self, of: {
                $0.contentSize.height - $0.containerSize.height
            }, action: { _, newValue in
                isLargerContent = newValue > 0
            })
            // contentOffset.y + top inset = distance scrolled from the very top, independent of safe-area insets
            .onScrollGeometryChange(for: CGFloat.self) {
                $0.contentOffset.y + $0.contentInsets.top
            } action: { oldValue, newValue in
                guard isDragging else { return }
                scrollOffset = newValue
                let isScrolledUp = oldValue < newValue

                if self.isScrolledUp != isScrolledUp {
                    // direction just reversed: rebase shiftOffset so progress starts counting from here
                    self.isScrolledUp = isScrolledUp
                    shiftOffset = newValue - (progress * distance)
                }

                // normalize distance scrolled since the last rebase into 0...1 for progress-driven UI (scale/opacity)
                let rawProgress = (newValue - shiftOffset) / distance
                let clampedProgress = rawProgress.clamped(to: 0 ... 1)
                withAnimation(.iSpring()) {
                    progress = clampedProgress
                }
            }
    }

    private var distance: CGFloat {
        100
    }
}
