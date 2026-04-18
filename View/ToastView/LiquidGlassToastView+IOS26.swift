//
//  LiquidGlassToastView+IOS26.swift
//  animation
//
//  Created on 4/18/26.

// MARK: - Key Concepts & Takeaways

//
// This file builds a toast notification system using iOS 26 Liquid Glass.
// Focus areas: animation sequencing, transitions, modifier ordering, and Environment.
//
// 1. **Animation Sequencing (withAnimation + logicallyComplete)**
//    When a new toast arrives while one is visible, we must: exit old -> enter new.
//    `logicallyComplete(after: 0.17)` tells SwiftUI "treat this animation as done
//    after 0.17s" so the completion block fires fast — even though the spring hasn't
//    fully settled. Without this, the new toast waits for the full spring duration,
//    causing a sluggish swap.
//
//    Why 0.17? The spring duration is 0.35s. At roughly half the duration, the old
//    toast has already covered ~80% of its exit distance (springs move fast initially,
//    then decelerate). This is the sweet spot — visually gone enough to start the
//    new toast, without waiting for the slow tail of the spring to settle.
//    - Too low (e.g. 0.05): new toast starts while old one is barely moving → overlap
//    - Too high (e.g. 0.35): waits for the full spring → sluggish gap between toasts
//    Rule of thumb: ~half the spring duration is a good starting point, then eyeball.
//
// 2. **Transitions: .offset(y:) on the toast, .identity on children**
//    The toast uses `.transition(.offset(y: 100))` to slide in from below.
//    But SwiftUI also applies the *default* fade transition to each `if let` child
//    (icon, button) — so they'd fade in independently on top of the slide, causing
//    a messy double-animation. `.transition(.identity)` tells those children:
//    "do nothing on your own insertion/removal; just ride the parent's transition."
//
//    Alternatives & tradeoffs:
//    - `.transition(.identity)` — simplest, zero visual cost. Best when children
//      should move as one unit with the parent. Used here.
//    - `.animation(nil)` on children — also suppresses their animation, but is
//      broader: it disables ALL animations on that subtree, not just transitions.
//      Could accidentally kill intentional state-change animations inside the child.
//    - Wrapping children in a non-conditional container (no `if let`) avoids the
//      insertion/removal entirely, but then you lose the ability to conditionally
//      show the icon/button, and you'd need placeholder spacing.
//
// 3. **Modifier Order Matters**
//    The current order is:
//      .padding -> .frame -> .clipShape -> .contentShape -> .glassEffect
//      -> .padding -> .offset -> .gesture -> .transition
//
//    Key ordering rules:
//    - `.clipShape` / `.contentShape` / `.glassEffect` BEFORE `.padding(.horizontal, 15)`
//      so the glass capsule doesn't include the outer margin.
//    - `.gesture` AFTER `.offset` — the gesture's coordinate space follows the
//      offset, so the drag target matches where the toast visually sits.
//      If `.gesture` came BEFORE `.offset`, the hit area would be at the
//      pre-offset position (bottom edge) while the toast is visually higher,
//      making swipe-to-dismiss feel broken.
//    - `.transition` LAST — it wraps the entire composed view so the slide-in
//      animation applies to the toast in its final position and shape.
//
// 4. **Environment Values — Why ForYouTabView can use showToast directly**
//    `LiquidGlassToastRootView` calls `.environment(\.showToast) { ... }` on its
//    `content`. In SwiftUI, environment values propagate DOWN the view tree to ALL
//    descendants — not just direct children. So:
//
//      LiquidGlassToastRootView  <-- sets .environment(\.showToast)
//        └─ TabView
//             └─ ForYouTabView   <-- reads @Environment(\.showToast) ✅
//
//    ForYouTabView doesn't need the value passed explicitly because it inherits it
//    from any ancestor. This is exactly what Environment solves: any view at any
//    depth can read the value without every intermediate view forwarding it.
//    The `@Entry` macro provides a default no-op closure, so views that read
//    `showToast` outside of a `LiquidGlassToastRootView` simply do nothing instead
//    of crashing — safe by default.
//
// 5. **Auto-Dismiss with Cancellation (DispatchWorkItem)**
//    `DispatchWorkItem` wraps a closure that can be both scheduled and cancelled.
//    Unlike a plain `DispatchQueue.main.asyncAfter { ... }` closure (fire-and-forget),
//    a DispatchWorkItem lets you call `.cancel()` before it fires.
//    Here, when a new toast arrives, we cancel the old item so its delayed dismiss
//    doesn't accidentally kill the new toast. Without cancellation, toast A's 3s timer
//    could fire and dismiss toast B that replaced it at 2s.
//
// 6. **iOS Layout Conventions — Where the "Magic Numbers" Come From**
//    Apple HIG defines two foundational values that most iOS layout derives from:
//    - **44pt** — minimum tap target size. Any interactive element should be >= 44x44pt.
//    - **16pt** — standard system margin/padding (List insets, nav content, safe areas).
//
//    Common derived values:
//      8  = 16 / 2    (tight spacing)
//      12 = 8 + 4     (compact padding)
//      16 = standard   (system margin)
//      32 = 16 x 2    (section spacing)
//      44 = tap target (minimum interactive size)
//
//    How the numbers in this file map to these conventions:
//    - `padding(.horizontal, 18)` — inner content padding. 16 is standard, but capsule
//      corners curve inward and eat into usable space, so +2pt compensates.
//    - `frame(height: 50)` — 44pt minimum tap target + 6pt visual breathing room.
//    - `padding(.horizontal, 15)` — outer screen margin. ~16pt standard, 15 aligns
//      better with tab bar item centering in this specific layout.
//    - `placementOffset: -60` — tab bar height (~49pt) + ~11pt spacing above it.
//    - `transitionOffset: 100` — far enough below screen bottom for a visible slide-in
//      without feeling slow. Roughly 2x the toast height.
//    - Drag threshold `> 30` — enough to distinguish intentional swipe from accidental
//      touch (> ~half of 44pt tap target), but not so high it feels unresponsive.

import SwiftUI

@available(iOS 26.0, *)
struct LiquidGlassToastTabBarDemoView: View {
    @State private var cartCount: Int = 0
    var body: some View {
        LiquidGlassToastRootView {
            TabView {
                Tab("For You", systemImage: "heart.text.square.fill") {
                    ForYouTabView(cartCount: $cartCount)
                }

                Tab("Products", systemImage: "macbook.and.iphone") {}

                Tab("More", systemImage: "safari") {}

                Tab("Bag", systemImage: "bag") {}
                    .badge(cartCount)

                Tab(role: .search) {}
            }
        }
    }
}

@available(iOS 26.0, *)
private struct ForYouTabView: View {
    @Binding var cartCount: Int
    /// These closures were set by LiquidGlassToastRootView (an ancestor).
    /// SwiftUI Environment propagates to ALL descendants, so no prop drilling needed.
    @Environment(\.showToast) private var showToast
    @Environment(\.dismissToast) private var dismissToast

    var body: some View {
        NavigationStack {
            List {
                Section("Demo") {
                    HStack {
                        Button("Add to Cart") {
                            showToast(.init(
                                title: "Added to Cart",
                                duration: 3,
                                placementOffset: -60,
                                symbol: "cart.fill",
                                actionTitle: "OK",
                                action: {
                                    cartCount += 1
                                    /// Returning true tells the toast to dismiss itself.
                                    /// Return false to keep the toast visible after the action.
                                    return true
                                }
                            )
                            )
                        }
                        Button("Notify") {
                            showToast(
                                .init(
                                    title: "Notification Enabled",
                                    duration: 3,
                                    placementOffset: -60
                                )
                            )
                        }

                        Button("Dismiss") {
                            dismissToast()
                        }
                    }
                    .buttonStyle(.glass)
                }
            }
            .navigationTitle("Glass Toast")
        }
    }

    private func undoCart() -> LiquidGlassToast {
        .init(
            title: "Removed from Cart",
            duration: 3,
            placementOffset: -60,
            symbol: "checkmark.circle.fill"
        )
    }
}

// MARK: - Toast Root Container

@available(iOS 26.0, *)
struct LiquidGlassToastRootView<Content: View>: View {
    @ViewBuilder var content: Content
    @State private var activeToast: LiquidGlassToast?
    /// DispatchWorkItem wraps a block that can be scheduled AND cancelled.
    /// When a new toast arrives, we `.cancel()` the old item so its delayed
    /// dismiss doesn't accidentally kill the new toast. See header point #5.
    @State private var toastDismissWorkItem: DispatchWorkItem?
    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .bottom) {
                GlassEffectContainer(spacing: 10) {
                    if let activeToast {
                        toastView(activeToast)
                    }
                }
                /// Keeps the container in layout when empty (prevents layout jump).
                /// The container itself is invisible; the toast inside drives visibility.
                .opacity(activeToast == nil ? 0 : 1)
            }

            // MARK: Environment Injection — any descendant can call showToast/dismissToast

            .environment(\.showToast) { toast in

                // MARK: Animation Sequencing (see header point #1)

                // Phase 1: Animate out the old toast.
                // `.logicallyComplete(after: 0.17)` fires the completion early
                // so the user doesn't wait for the full spring to settle.
                withAnimation(animation.logicallyComplete(after: 0.17), completionCriteria: .logicallyComplete) {
                    if activeToast != nil {
                        activeToast = nil
                    }
                } completion: {
                    // Phase 2: Cancel old auto-dismiss timer, animate in the new toast.
                    toastDismissWorkItem?.cancel()

                    withAnimation(animation) {
                        activeToast = toast
                    }

                    // Phase 3: Schedule new auto-dismiss.
                    toastDismissWorkItem = .init(block: dismiss)
                    let duration = max(toast.duration, 1) // floor to 1s
                    if let toastDismissWorkItem {
                        DispatchQueue.main.asyncAfter(
                            deadline: .now() + duration,
                            execute: toastDismissWorkItem
                        )
                    }
                }
            }
            .environment(\.dismissToast) { dismiss() }
    }

    private func toastView(_ toast: LiquidGlassToast) -> some View {
        HStack(spacing: 10) {
            if let symbol = toast.symbol {
                Image(systemName: symbol)
                    .font(.title3)
                    .foregroundStyle(Color.primary)
                    /// `.identity` = "no transition." Without this, SwiftUI applies a
                    /// default fade to this `if let` child, clashing with the parent's
                    /// slide-in. See header point #2 for alternatives & tradeoffs.
                    .transition(.identity)
            }

            Text(toast.title)
                .font(.body)
                .lineLimit(1)

            Spacer(minLength: 0)

            if let actionTitle = toast.actionTitle,
               let action = toast.action
            {
                Button {
                    if action() { dismiss() }
                } label: {
                    Text(actionTitle)
                        .foregroundColor(toast.actionTint)
                }
                /// Same reason as the icon above — ride the parent's transition.
                .transition(.identity)
            }
        }

        // MARK: Modifier Order (see header point #3)

        // Shape modifiers go BEFORE outer padding — glass capsule shouldn't include margin.
        .padding(.horizontal, 18)
        .frame(height: 50)
        .clipShape(.capsule)
        .contentShape(.capsule)
        .glassEffect(.regular, in: .capsule)
        .padding(.horizontal, 15)
        // .offset BEFORE .gesture — so the gesture's coordinate space matches where
        // the toast visually sits. Reversing these would leave the drag target at
        // the pre-offset position (screen bottom) while the toast floats above it.
        .offset(y: toast.placementOffset)
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.height > 30 { dismiss() }
                }
        )
        // .transition LAST — wraps the fully composed view so the slide-in
        // animates the toast in its final shape and position as one unit.
        .transition(.offset(y: toast.transitionOffset))
    }

    private func dismiss() {
        withAnimation(animation) {
            activeToast = nil
            toastDismissWorkItem?.cancel()
        }
    }

    private let animation: Animation = .interpolatingSpring(duration: 0.35, bounce: 0, initialVelocity: 0)
}

// MARK: - Custom Environment Keys (see header point #4)

// Default = no-op closures, so reading these outside of a LiquidGlassToastRootView
// does nothing instead of crashing. The root container overrides these with real
// implementations via `.environment(\.showToast) { ... }`.
private extension EnvironmentValues {
    @Entry var showToast: (LiquidGlassToast) -> Void = { _ in }
    @Entry var dismissToast: () -> Void = {}
}

// MARK: - Toast Data Model

private struct LiquidGlassToast: Identifiable {
    private(set) var id: String = UUID().uuidString
    var title: String
    var duration: CGFloat
    /// How far the toast sits above the bottom edge (use negative for above tab bar)
    var placementOffset: CGFloat
    /// How far off-screen the toast starts before sliding in
    var transitionOffset: CGFloat = 100
    var symbol: String? = nil
    var actionTitle: String? = nil
    var actionTint: Color = .accentColor
    /// Returns Bool: true = dismiss toast after action, false = keep toast visible
    var action: (() -> Bool)? = nil
}

@available(iOS 26.0, *)
#Preview {
    LiquidGlassToastTabBarDemoView()
}
