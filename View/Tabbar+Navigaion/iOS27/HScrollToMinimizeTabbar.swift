//
//  HScrollToMinimizeTabbar.swift
//  animation
//
//  Created on 8/12/26.
//  Photos App IOS27

import SwiftUI

/// Photos-style tab bar that minimizes on scroll, with a segmented picker that moves into the
/// space the minimized bar frees up.
///
/// SwiftUI exposes `tabBarMinimizeBehavior` but not whether the bar is *currently* minimized, so
/// this demo recovers that state from UIKit. Techniques worth taking away:
///
/// 1. **A `UIViewRepresentable` can be a probe rather than a view.** `TabBarMinimizeObserver`
///    draws nothing. It exists so its backing `UIView` can be located inside the UIKit hierarchy
///    that hosts SwiftUI, then walked upward to reach the `UITabBarController`. Hosting it in
///    `.background` keeps it out of the content's layout.
/// 2. **Modifier order is structural here, not cosmetic.** `.compositingGroup()` is what makes
///    that walk land where it expects — see the note at the call site.
/// 3. **KVO is the bridge back into SwiftUI.** UIKit never publishes "minimized"; it hides one
///    platter and shows another. Observing `isHidden` on both turns that into a `Bool` binding.
/// 4. **Undocumented structure needs an explicit failure path.** Discovery can only ever be a
///    heuristic, so it reports through `error` instead of guessing, and the caller stays able to
///    fall back rather than silently tracking the wrong view.
/// 5. **Strict concurrency shapes the bridge.** UIKit properties are `@MainActor`-isolated while
///    KVO handlers are `@Sendable`; reconciling the two is what the `Coordinator` annotations are
///    for.
///
/// The trade-off to stay clear-eyed about: everything from point 2 onward leans on private view
/// hierarchy details that can change in any OS release. Acceptable in a demo — in shipping code
/// it belongs behind the fallback that `error` enables.
@available(iOS 27.0, *)
struct HorizontalScrollToMinimizeTabBarDemo: View {
    @State private var isMinimized: Bool = false
    @State private var activePickerTab: String = "All"
    @State private var searchText: String = ""
    @State private var isSearchPresented: Bool = false
    @FocusState private var searchFocus: Bool
    @State private var safeAreaBottomEdge: CGFloat = 0
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    /// The picker occupies the same space as the search field, so it yields to search
    /// whether search was activated by tab selection or by focusing the field.
    private var showsPicker: Bool {
        isMinimized && !isSearchPresented && !searchFocus
    }

    /// Without a bottom safe area inset the tab bar sits nearer the screen edge, so the picker
    /// has to ride higher to stay clear of it. The remaining split tracks the two control sizes.
    private var pickerOffset: CGFloat {
        if safeAreaBottomEdge == 0 { return -28 }
        return horizontalSizeClass == .regular ? -3 : 6
    }

    var body: some View {
        TabView {
            Tab.init {
                NavigationStack {
                    ScrollView(.vertical) {
                        LazyVGrid(columns: Array(repeating: GridItem(spacing: 4), count: 3), spacing: 4) {
                            ForEach(0 ..< 50) { _ in
                                Rectangle()
                                    .fill(.fill.tertiary)
                                    .aspectRatio(1, contentMode: .fit)
                            }
                        }
                    }
                    .safeAreaPadding(.vertical, 15)
                    .scrollEdgeEffectStyle(.soft, for: .vertical)
                    .toolbar {
                        ToolbarItem(placement: .subtitle) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Library")
                                    .font(.title.bold())
                                Text("Aug 12, 2026")
                                    .font(.caption2)
                            }
                            .padding(.trailing, 15)
                        }

                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Options", systemImage: "line.3.horizontal.decrease") {}
                        }

                        ToolbarSpacer(.fixed, placement: .topBarTrailing)

                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Select") {}
                        }
                    }
                    .defaultScrollAnchor(.bottom)
                }
            } label: {
                Image(systemName: "photo.on.rectangle")
                Text("Library")
            }

            Tab.init {} label: {
                Image(systemName: "rectangle.stack")
                Text("Collections")
            }

            Tab(role: .search) {
                NavigationStack {
                    VStack {}
                        .navigationTitle("Search")
                }
                .searchable(text: $searchText, isPresented: $isSearchPresented)
                .searchFocused($searchFocus)
            } label: {
                Image(systemName: "magnifyingglass")
                Text("Search")
            }
        }
        .tabBarMinimizedBehaviorWithUpdate(isMinimized: $isMinimized, behavior: .onScrollUp) {
            print("Can't add TabBarMinimizeObserver")
        }
//        .tabViewSearchActivation(.searchTabSelection) /// iOS26 search bar style
        .overlay(alignment: .bottom) {
            Picker("", selection: $activePickerTab) {
                ForEach(["Years", "Months", "All"], id: \.self) {
                    Text($0)
                        .tag($0)
                }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .controlSize(horizontalSizeClass == .regular ? .regular : .large)
            .glassEffect(.regular, in: .capsule)
            .frame(maxWidth: 350)
            .opacity(showsPicker ? 1 : 0)
            .offset(y: pickerOffset)
            /// Minimizing collapses the tab bar to a circular platter at the leading edge and
            /// leaves the search item at the trailing edge. This reserves room for both — the
            /// ~48pt platter plus spacing on each side — so the picker sits between them
            /// instead of underneath. Empirical, not a published metric: it has to be revisited
            /// if the platter's rendered size changes.
            .padding(.horizontal, 85)
            .animation(.easeInOut(duration: 0.12), value: showsPicker)
        }
        /// Reads geometry without a `GeometryReader`, which would otherwise expand to fill and
        /// change the layout it is measuring. Note the first render happens before this resolves,
        /// so `safeAreaBottomEdge` is 0 for that frame — which `pickerOffset` treats as the
        /// no-inset device rather than as "unknown".
        .onGeometryChange(for: CGFloat.self) {
            $0.safeAreaInsets.bottom
        } action: { newValue in
            safeAreaBottomEdge = newValue
        }
    }
}

@available(iOS 27.0, *)
#Preview {
    HorizontalScrollToMinimizeTabBarDemo()
}

@available(iOS 27.0, *)
private extension TabView {
    @MainActor func tabBarMinimizedBehaviorWithUpdate(
        isMinimized: Binding<Bool>,
        behavior: TabBarMinimizeBehavior,
        error: @escaping () -> Void
    ) -> some View {
        modifier(
            TabBarMinimizeHelper(
                isMinimized: isMinimized,
                behavior: behavior,
                error: error
            )
        )
    }
}

@available(iOS 27.0, *)
private struct TabBarMinimizeHelper: ViewModifier {
    @Binding var isMinimized: Bool
    var behavior: TabBarMinimizeBehavior
    var error: () -> Void
    /// Only this property's *changes* matter, never its value: flipping it swaps which branch
    /// of the `if`/`else` below is taken, which is what rebuilds the observer.
    @State private var changeTrigger: Bool = false
    func body(content: Content) -> some View {
        content
            /// `.background` hosts the probe because it adds no layout of its own — the observer
            /// needs a place in the view hierarchy, not space on screen.
            .background {
                /// Both branches are deliberately identical. A `@ViewBuilder` `if`/`else`
                /// compiles to `_ConditionalContent`, and SwiftUI gives each branch its own
                /// structural identity — so switching branches tears the observer down
                /// (releasing the coordinator, whose `deinit` invalidates the observations)
                /// and builds a fresh one, re-running `makeUIView` and platter discovery.
                ///
                /// That rebuild is what keeps the state accurate: `updateUIView` does no work,
                /// and the observations are bound to the specific tab bar subviews found at
                /// creation time — which UIKit replaces when the minimize behavior changes.
                /// Reusing one instance would leave the coordinator watching stale views.
                ///
                /// `.id(changeTrigger)` on a single instance expresses the same thing.
                if changeTrigger {
                    TabBarMinimizeObserver(isMinimized: $isMinimized) {
                        isMinimized = false
                        error()
                    }
                } else {
                    TabBarMinimizeObserver(isMinimized: $isMinimized) {
                        isMinimized = false
                        error()
                    }
                }
            }
            /// Load-bearing, not cosmetic. Flattening the modified content into a single backing
            /// view gives the probe a predictable ancestor to find: the `compositingGroup` local
            /// in `addObserver` is exactly this view. Drop this line and the depth of the walk
            /// changes, so discovery fails.
            .compositingGroup()
            .tabBarMinimizeBehavior(behavior)
            /// The new behavior may not minimize at all, so drop back to the maximized state
            /// rather than carrying the old value across the rebuild.
            .onChange(of: behavior) { _, _ in
                isMinimized = false
                changeTrigger.toggle()
            }
    }
}

/// Reports the tab bar's minimized state, which SwiftUI does not expose, by reading
/// `UITabBar`'s subviews.
///
/// The technique comes from inspecting the live view hierarchy:
/// - A plain tab bar has a single platter subview.
/// - Enabling a minimize behavior adds a second one, so there is a dedicated platter
///   for each state — one minimized, one maximized. Exactly one is visible at a time,
///   so observing `isHidden` on both yields the current state.
/// - A prominent or search item appends two further auxiliary subviews, which are not
///   platters and must be filtered out before the remaining pair can be identified.
///
/// The two platters are told apart by shape rather than order: the minimized platter is
/// circular, so its width equals its height.
///
/// All of this rests on undocumented internal structure. When the expected pair cannot
/// be found the observer reports failure through `error` instead of guessing, leaving the
/// caller to fall back rather than silently track the wrong view.
private struct TabBarMinimizeObserver: UIViewRepresentable {
    @Binding var isMinimized: Bool
    var error: () -> Void
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        /// The walk up to the tab bar in `addObserver` needs this view already installed in the
        /// hierarchy, so it is deferred one turn of the run loop. Discovery is attempted once —
        /// if it loses the race against UIKit building the platters, `error` reports it and
        /// nothing is observed until the next rebuild.
        DispatchQueue.main.async {
            addObserver(view, context: context)
        }
        return view
    }

    /// Nothing to push: the only channel back to SwiftUI is the binding, and a binding stays
    /// connected to its source of truth on its own. The cost of leaving this empty is that a
    /// changed `behavior` cannot be handled here — hence the identity rebuild in
    /// `TabBarMinimizeHelper`.
    func updateUIView(_: UIView, context _: Context) {}

    private func addObserver(_ view: UIView, context: Context) {
        /// Climb out of the probe to the compositing group, descend to the last-added subviews,
        /// then cross from views to controllers: `next` is `UIResponder.next`, which for a view
        /// owned by a view controller returns that controller. Every step is positional, so this
        /// is the most brittle part of the file — a wrong guess yields `nil` rather than a crash,
        /// and `error` reports it.
        let compositingGroup = view.superview?.superview
        let tabBarController = compositingGroup?.subviews.last?.subviews.last?.next as? UITabBarController
        /// Drop the auxiliary subviews a prominent or search item contributes, leaving the
        /// minimized and maximized platters. Matching a private class name by string is the only
        /// handle available; if Apple renames it the filter quietly stops matching, which is why
        /// the pair below is validated instead of assumed.
        let views = (tabBarController?.tabBar.subviews ?? [])
            .filter { !String(describing: type(of: $0)).contains("UITabBarAuxiliary") }
            .prefix(2)

        if let minimizedTab = views.first(where: { $0.isMinimizedTabItem }),
           let maximizedTab = views.first(where: { $0.isMinimizedTabItem == false }),
           views.count == 2, minimizedTab != maximizedTab
        {
            context.coordinator.addMinimizedObserver(minimizedTab)
            context.coordinator.addMaximizedObserver(maximizedTab)
        } else {
            error()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    /// `UIView.isHidden` is main actor-isolated, so both the key path and the
    /// observed state have to live on the main actor.
    @MainActor
    class Coordinator: NSObject {
        /// A snapshot of the representable as it was when the coordinator was created — the
        /// struct is copied, and nothing here refreshes it. Reading `parent.error` later would
        /// therefore mean reading a stale closure. Writing `parent.isMinimized` is fine only
        /// because a `Binding` carries accessors into the state that owns it, so it keeps
        /// working after the struct that held it has been replaced.
        var parent: TabBarMinimizeObserver
        init(parent: TabBarMinimizeObserver) {
            self.parent = parent
        }

        /// The coordinator owns both observations and the handlers capture it back, so `[weak
        /// self]` below is what allows this to run at all. Without it the cycle keeps the
        /// coordinator alive and the observers outlive the views they watch.
        deinit {
            minimizedObserver?.invalidate()
            maximizedObserver?.invalidate()
        }

        var minimizedObserver: NSKeyValueObservation?
        var maximizedObserver: NSKeyValueObservation?

        /// Three details in both handlers below are easy to misread:
        ///
        /// - `.initial` fires the handler once at registration, so the starting state is seeded
        ///   without a separate read. `.new` covers every change after that.
        /// - The guard passes when `isHidden` becomes **false**, i.e. when this platter becomes
        ///   visible. Each observer only reacts to its own platter appearing, which is why two
        ///   observers writing one binding cannot fight: exactly one platter is visible.
        /// - `assumeIsolated` asserts "this is already the main thread" and traps if it is not.
        ///   It is not a hop. `Task { @MainActor in }` would compile too, but would defer the
        ///   write to a later turn of the run loop, landing the state change a frame after the
        ///   animation it is meant to accompany.
        ///
        /// The change handler is `@Sendable`, but KVO delivers it synchronously on the
        /// thread that mutated `isHidden` — always the main thread for a `UIView`.
        func addMinimizedObserver(_ view: UIView) {
            minimizedObserver = view.observe(\.isHidden, options: [.new, .initial]) { [weak self] _, change in
                guard let newValue = change.newValue, !newValue else { return }
                MainActor.assumeIsolated {
                    self?.parent.isMinimized = true
                }
            }
        }

        func addMaximizedObserver(_ view: UIView) {
            maximizedObserver = view.observe(\.isHidden, options: [.new, .initial]) { [weak self] _, change in
                guard let newValue = change.newValue, !newValue else { return }
                MainActor.assumeIsolated {
                    self?.parent.isMinimized = false
                }
            }
        }
    }
}

private extension UIView {
    /// The minimized tab bar platter is circular, so a square frame distinguishes it from
    /// its maximized counterpart.
    ///
    /// Two assumptions ride on this. Exact `CGFloat` equality holds only because UIKit lays the
    /// platter out as a literal square, and the frame has to be laid out already — which is the
    /// other reason discovery is deferred to the next run loop turn.
    var isMinimizedTabItem: Bool {
        frame.width == frame.height
    }
}
