//
//  CustomSideMenu+iOS26.swift
//  animation
//
//  Created on 5/9/26.
//  Twitter/X app side menu
//
//  ──────────────────────────────────────────────────────────────────────────
//  Learning points for SwiftUI newcomers
//  ──────────────────────────────────────────────────────────────────────────
//  1. Progress-driven animation: a single `progress: CGFloat` (0...1) drives
//     opacity, scale, shadow, and offset together. Map gesture translation →
//     progress, then let SwiftUI interpolate everything in lockstep.
//  2. ViewBuilder closures with parameters: `(progress) -> View` lets the
//     parent feed state down to child views, so callers can react to the
//     menu's open amount without a separate @Binding.
//  3. ZStack + offset trick: the menu lives at `.leading` underneath the
//     content. We don't move the menu — we slide the *content* to the right
//     to reveal it. Cheaper to animate one offset than two.
//  4. UIGestureRecognizerRepresentable (iOS 18+): bridges UIKit gestures
//     into SwiftUI. Needed here because SwiftUI's DragGesture can't
//     coordinate with a child UIScrollView's pan (see Coordinator below).
//  5. iOS 26 APIs used: `ConcentricRectangle` (corner radius matches the
//     device screen), `Tab(_:systemImage:value:)` value-based TabView, and
//     `toolbarVisibility(.hidden, for:)`.
//  ──────────────────────────────────────────────────────────────────────────
import SwiftUI

struct CustomIOS26SideMenuDemoView: View {
    @State private var activeTab: Int = 0
    // NavigationPath is a type-erased stack for programmatic navigation.
    // Push with `.append(value)`, pop by mutating the path. Bind it to
    // NavigationStack(path:) to drive routing from code, not just from links.
    @State private var navigationPath: NavigationPath = .init()
    @State private var isExpanded: Bool = false
    var body: some View {
        // Disable the side-menu swipe once we've pushed a detail view —
        // otherwise the swipe-to-go-back gesture would fight the menu pan.
        let isMenuEnabled = navigationPath.isEmpty
        CustomIOS26SideMenu(isEnabled: isMenuEnabled, isExpanded: $isExpanded) { _ in
            VStack {
                DummySideBar()

                Button {
                    isExpanded = false
                    navigationPath.append("Settings")
                } label: {
                    Text("Go to Settings")
                }
                .padding(.top, 15)
            }
        } content: { _ in
            NavigationStack(path: $navigationPath) {
                // iOS 18+ value-based TabView. Each `Tab(...)` carries its own
                // `value`, and `selection:` binds to that value type. Cleaner
                // than the older `.tabItem { }` modifier on arbitrary views.
                TabView(selection: $activeTab) {
                    Tab("Home", systemImage: "house", value: 0) {
                        ScrollView(.vertical) {
                            VStack(spacing: 10) {
                                NavigationLink(value: "Detail View") {
                                    Rectangle()
                                        .fill(.indigo)
                                        .frame(height: 45)
                                }

                                // Horizontal pager built from a plain ScrollView:
                                // `containerRelativeFrame(.horizontal)` makes
                                // each child fill the parent's width, and
                                // `scrollTargetBehavior(.paging)` snaps page-by-
                                // page. No UIPageViewController needed.
                                ScrollView(.horizontal) {
                                    HStack(spacing: 0) {
                                        Rectangle()
                                            .fill(.red)
                                            .containerRelativeFrame(
                                                .horizontal
                                            )
                                        Rectangle()
                                            .fill(.gray)
                                            .containerRelativeFrame(
                                                .horizontal
                                            )
                                    }
                                }
                                .scrollTargetBehavior(.paging)
                                .frame(height: 220)
                            }
                        }
                    }
                    Tab("Search", systemImage: "magnifyingglass", value: 1) {}
                    Tab("Notifications", systemImage: "bell", value: 2) {}
                    Tab("Profiles", systemImage: "person", value: 3) {}
                }
                .toolbarVisibility(.hidden, for: .navigationBar)
                // navigationDestination registers a router for a value type.
                // Any `NavigationLink(value:)` of String anywhere inside this
                // stack will resolve here — destinations are decoupled from
                // links, which scales better than nested NavigationLinks.
                .navigationDestination(for: String.self) { value in
                    Text("Demo").navigationTitle(value)
                }
            }
        }
    }
}

// Generic over MenuContent and Content so callers can pass any view types
// without erasing to AnyView. `@ViewBuilder` on the closures lets callers use
// the usual `if`/`ForEach`/multiple-statement DSL inside.
struct CustomIOS26SideMenu<MenuContent: View, Content: View>: View {
    // Enable or disable the side-menu pan gesture from the outside (e.g.
    // turn it off when a detail view is pushed).
    var isEnabled: Bool = true
    @Binding var isExpanded: Bool
    var sideBarWidth: CGFloat = 280

    // Closures receive the live `progress` (0...1) so callers can fade or
    // scale their own UI in sync with the menu animation.
    @ViewBuilder var menuContent: (_ progress: CGFloat) -> MenuContent
    @ViewBuilder var content: (_ progress: CGFloat) -> Content
    /// View Properties
    // `progress` is the visual driver; `xOffset` is its raw input from the
    // gesture. They're kept in sync so children can read progress directly.
    @State private var progress: CGFloat = 0
    @State private var xOffset: CGFloat = 0
    // Toggling this `Bool` triggers `.sensoryFeedback` below — declarative
    // haptics in SwiftUI fire on *value change*, not on a function call.
    @State private var haptics: Bool = false
    var body: some View {
        // ZStack alignment .leading: the menu sits pinned to the left edge,
        // and `content` is layered on top. Sliding `content` to the right
        // reveals the menu underneath.
        ZStack(alignment: .leading) {
            menuContent(progress)
                .frame(width: sideBarWidth)
                .frame(maxHeight: .infinity)
                // Subtle reveal: menu fades in and scales from 95% → 100%
                // as the user pulls the content aside. Cheap polish that
                // makes the interaction feel layered rather than flat.
                .opacity(progress)
                .scaleEffect(0.95 + (0.05 * progress))

            content(progress)
                // Forces this view to match its parent's horizontal size.
                // Without this, content would shrink-wrap and the offset
                // animation wouldn't cover the full screen.
                .containerRelativeFrame(.horizontal)
                .frame(maxHeight: .infinity)
                .background {
                    backgroundShape
                        .fill(.background)
                        .ignoresSafeArea()
                }
                .overlay {
                    // Dim/scrim layer that also captures taps to dismiss.
                    // Its opacity tracks progress so it only intercepts
                    // touches once the menu is partially open.
                    backgroundShape
                        .fill(.tertiary)
                        .stroke(.fill.secondary, lineWidth: 1)
                        .ignoresSafeArea()
                        .contentShape(.rect)
                        .onTapGesture {
                            withAnimation(animation) {
                                dismissMenu()
                            }
                        }
                        .opacity(progress)
                }
                // Clip the content (and its overlay) to the rounded shape so
                // the corners are visible while sliding.
                .mask {
                    backgroundShape
                        .ignoresSafeArea()
                }
                // compositingGroup() flattens this view into a single layer
                // *before* the shadow is applied. Without it, the shadow
                // would be drawn per-subview and bleed through the mask.
                .compositingGroup()
                .shadow(color: .black.opacity(0.06 * progress), radius: 5, x: -10, y: 0)
                .offset(x: xOffset)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Required for the gesture to fire on empty regions of the ZStack;
        // without contentShape, hit-testing only counts opaque content.
        .contentShape(.rect)
        .gesture(
            CustomSideMenuGesture(isEnabled: isEnabled, isExpanded: $isExpanded) { gesture in
                let state = gesture.state
                // When the menu is already open we offset translation by
                // sideBarWidth so the gesture continues from the open
                // position instead of jumping back to 0.
                let translation = gesture.translation(in: gesture.view).x +
                    (isExpanded ? sideBarWidth : 0)
                // Velocity is scaled down (÷5) so a flick doesn't overshoot
                // the threshold by a huge amount; it's a tunable feel knob.
                let velocity = gesture.velocity(in: gesture.view).x / 5

                if state == .began || state == .changed {
                    // Live tracking — clamp so the user can't drag past
                    // the open or closed position.
                    xOffset = translation.clamped(to: 0 ... sideBarWidth)
                    progress = xOffset / sideBarWidth
                } else {
                    // Release: project where the user *would* land using
                    // velocity, and snap to whichever side is closer.
                    withAnimation(animation) {
                        if (xOffset + velocity) > (sideBarWidth / 2) {
                            expandMenu()
                        } else {
                            dismissMenu()
                        }
                    }
                }
            }
        )
        // Declarative haptics — fires whenever `haptics` toggles. No need
        // to call into UIImpactFeedbackGenerator manually.
        .sensoryFeedback(.impact(weight: .light), trigger: haptics)
        // Lets parent code drive the menu programmatically (e.g. tapping
        // a "Settings" button sets isExpanded = false to close the menu
        // before navigating). The `progress != 1/0` checks avoid redundant
        // animations when the binding changes mid-gesture.
        .onChange(of: isExpanded) { _, newValue in
            withAnimation(animation) {
                if newValue, progress != 1 {
                    expandMenu()
                }

                if !newValue, progress != 0 {
                    dismissMenu()
                }
            }
        }
    }

    // `interactiveSpring` is tuned for gesture-driven UIs: it responds
    // instantly to velocity hand-offs and settles quickly. Prefer this over
    // `.spring()` when finishing a drag-to-snap interaction.
    var animation: Animation {
        .interactiveSpring(duration: 0.2, extraBounce: 0.02)
    }

    func expandMenu() {
        if !isExpanded { haptics.toggle() }
        /// Expand
        xOffset = sideBarWidth
        progress = 1
        isExpanded = false
    }

    func dismissMenu() {
        if isExpanded { haptics.toggle() }

        /// Reset
        xOffset = 0
        progress = 0
        isExpanded = false
    }

    // ConcentricRectangle (iOS 26+) auto-matches the device's screen corner
    // radius, so the inset content stays "concentric" with the display
    // bezel. On older OSes we fall back to a fixed radius.
    var backgroundShape: some Shape {
        if #available(iOS 26, *) {
            AnyShape(ConcentricRectangle(corners: .concentric, isUniform: true))
        } else {
            AnyShape(RoundedRectangle(cornerRadius: 45))
        }
    }
}

/// Why a UIKit pan gesture instead of SwiftUI's DragGesture?
/// SwiftUI's DragGesture has no public hooks to coordinate with sibling
/// scroll views — it either wins or loses. A `UIPanGestureRecognizer` lets
/// us implement `UIGestureRecognizerDelegate` callbacks to:
///   • decide *when* to begin (only on horizontal swipes, see below), and
///   • defer to a horizontal scroll view until it has scrolled to its
///     leading edge (so swiping right inside a paged carousel scrolls the
///     carousel, but swiping right *from* the leading edge opens the menu).
///
/// `UIGestureRecognizerRepresentable` (iOS 18+) is the SwiftUI bridge — it
/// works like `UIViewRepresentable` but for gesture recognizers. The four
/// methods below mirror the make/update/handle/coordinator lifecycle.
private struct CustomSideMenuGesture: UIGestureRecognizerRepresentable {
    var isEnabled: Bool
    @Binding var isExpanded: Bool
    var handle: (UIPanGestureRecognizer) -> Void

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let gesture = UIPanGestureRecognizer()
        gesture.delegate = context.coordinator
        // Single-finger only — prevents pinches/two-finger scrolls from
        // accidentally driving the menu.
        gesture.maximumNumberOfTouches = 1
        return gesture
    }

    func updateUIGestureRecognizer(
        _ recognizer: UIPanGestureRecognizer,
        context _: Context
    ) {
        recognizer.isEnabled = isEnabled
    }

    func handleUIGestureRecognizerAction(
        _ recognizer: UIPanGestureRecognizer,
        context _: Context
    ) {
        handle(recognizer)
    }

    func makeCoordinator(converter _: CoordinateSpaceConverter) -> Coordinator {
        Coordinator(parent: self)
    }

    // The Coordinator owns delegate callbacks for the recognizer. Same
    // pattern as UIViewRepresentable: SwiftUI struct = config, Coordinator
    // class = the long-lived object UIKit can hold a reference to.
    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var parent: CustomSideMenuGesture
        init(parent: CustomSideMenuGesture) {
            self.parent = parent
        }

        // Only claim the touch if the user is moving horizontally:
        //   • swiping right (open from closed), or
        //   • swiping left while already expanded (close).
        // This prevents the menu from hijacking vertical scrolls.
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            if let panGesture = gestureRecognizer as? UIPanGestureRecognizer {
                let velocity = panGesture.velocity(in: panGesture.view)
                let isHorizontalSwipe = abs(velocity.x) > abs(velocity.y)
                return (isHorizontalSwipe && velocity.x > 0) ||
                    (isHorizontalSwipe && velocity.x < 0 && parent.isExpanded)
            }
            return false
        }

        // Coexistence with horizontal scroll views: tell UIKit our pan must
        // wait for any UIScrollView's pan to *fail* before we begin — but
        // only when that scroll view is at its leading edge (offset ≤ 0).
        // Effect: inside a paged carousel, swipe-right scrolls the carousel
        // until it can't anymore, then the menu takes over.
        func gestureRecognizer(_: UIGestureRecognizer, shouldBeRequiredToFailByOtherGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            if let scrollView = otherGestureRecognizer.view as? UIScrollView {
                let offset = scrollView.contentOffset.x
                return offset <= 0
            }
            return false
        }
    }
}

#Preview {
    CustomIOS26SideMenuDemoView()
}
