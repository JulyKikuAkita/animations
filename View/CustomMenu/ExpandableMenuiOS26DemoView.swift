//
//  ExpandableMenuiOS26DemoView.swift
//  animation
//
//  Created on 12/18/25.
//  Standalone demo (not wired into the app's demo browser; preview-only).
//
//  TODO: Filename mismatch
//        The `iOS26` suffix is misleading — this file uses NO
//        iOS 26-only APIs. There's no `@available(iOS 26.0, *)`
//        gate, no `.glassEffect`, no `GlassEffectContainer`. It
//        compiles back to iOS 16+. Either drop the `iOS26` suffix
//        or add iOS 26 enhancements (e.g. swap `.ultraThinMaterial`
//        for `.glassEffect(.regular)`) to justify the name.
//
//  Learning point
//  ──────────────
//  Apple-Books-style FAB-to-menu reveal: a circular floating action
//  button taps open into a grid of action buttons, with the source
//  button morphing into the menu's anchor. Closes on tap-anywhere
//  outside. The headline trick is using `visualEffect` to scale +
//  blur the source FAB so it APPEARS to expand into the menu, even
//  though the menu is a separate view tree.
//
//  Two-layer reveal:
//    • The FAB blurs out + shrinks via `visualEffect`.
//    • The menu container blurs in + scales up from the FAB's
//      anchor.
//  Synchronised on a single `progress: CGFloat` (or Bool) so they
//  always read as one continuous gesture, never two parallel
//  animations fighting each other.
//
//  Key APIs
//  ────────
//  • `.visualEffect { content, proxy in ... }` — runs per-item on
//    every layout tick, ideal for tying a transform to a state value.
//  • `.allowsHitTesting(false)` on the dim backdrop while menu is
//    closed — prevents stealing taps when there's nothing to tap.
//  • `.transition(.identity)` on the menu container — opt OUT of
//    SwiftUI's default insert/remove transition so our custom
//    blur+scale runs alone.
//  • `.ultraThinMaterial` — chrome for the menu surface; iOS 15+.
//
//  How to apply
//  ────────────
//  Reach for this when a single FAB triggers a small set of
//  related actions (compose, share, attach). Keep the action count
//  ≤ 6; beyond that, a sheet reads better.
//
//  See also
//  ────────
//  • MorphActionButtoniOS26.swift — alternative FAB-morph using
//    `fullScreenCover` instead of an inline overlay.
//  • MorphCustomMenuDemoView.swift — radial menu variant of the
//    same source-button-expands-to-menu idea.
//  • GlassMorphEffectMenuiOS26.swift — iOS 26 sibling using
//    `.glassEffect` for the menu surface.
//
import SwiftUI

struct ExpandableMenuiOS26DemoView: View {
    @State private var isPresented: Bool = false
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("iPhone Guide") {}

                NavigationLink("iPad Guide") {}
            }
            .navigationTitle("Apple Books")
        }
        .overlay {
            ZStack(alignment: .bottomTrailing) {
                Rectangle()
                    .fill(.primary.opacity(isPresented ? 0.2 : 0))
                    .allowsHitTesting(isPresented)
                    .onTapGesture {
                        isPresented = false
                    }
                    .animation(animation, value: isPresented)
                    .ignoresSafeArea()

                MiniatureMenuAction(animation: animation, isPresented: $isPresented) {
                    actionContent()
                } background: {
                    ZStack {
                        Capsule()
                            .fill(.background)
                        Capsule()
                            .fill(.ultraThinMaterial)
                    }
                    .shadow(color: .gray.opacity(0.5), radius: 1)
                }
                .padding(.trailing, 15)
                .padding(.bottom, 10)
            }
        }
    }

    func actionContent() -> some View {
        VStack(spacing: 10) {
            CustomMenuButton(title: "Search Book", symbol: "magnifyingglass", isPresented: $isPresented)
                .frame(width: 250, height: 45)
            CustomMenuButton(title: "Theme & Settings", symbol: "textformat.size", isPresented: $isPresented)
                .frame(width: 250, height: 45)

            HStack(spacing: 10) {
                CustomMenuSectionButton(symbol: "square.and.arrow.up", isPresented: $isPresented)
                CustomMenuSectionButton(symbol: "lock.rotation", isPresented: $isPresented)
                CustomMenuSectionButton(symbol: "pawprint", isPresented: $isPresented)
                CustomMenuSectionButton(symbol: "bookmark", isPresented: $isPresented)
            }
            .font(.title3)
            .fontWeight(.medium)
            .frame(width: 250, height: 50)
        }
        .foregroundStyle(.primary)
    }

    var animation: Animation {
        .smooth(duration: 0.5, extraBounce: 0)
    }
}

struct MiniatureMenuAction<Actions: View, Background: View>: View {
    var innerScaling: CGFloat = 1.0
    var minimizedButtonSize: CGSize = .init(width: 50, height: 50)
    var animation: Animation
    @Binding var isPresented: Bool
    @ViewBuilder var actions: Actions
    @ViewBuilder var background: Background

    var body: some View {
        actions
            .allowsHitTesting(isPresented)
            .contentShape(.rect)
            .compositingGroup()
            /// Using visual effect modifier to scaling actions to fit the button size
            .visualEffect { [innerScaling, minimizedButtonSize, isPresented] content, proxy in
                let maxValue = max(proxy.size.width, proxy.size.height)
                let minButtonValue = min(minimizedButtonSize.width, minimizedButtonSize.height)
                let fitScale = minButtonValue / maxValue
                let modifiedInnerScale = 0.55 * innerScaling // this is to scale content
                return content
                    .scaleEffect(isPresented ? 1 : modifiedInnerScale)
                    .scaleEffect(isPresented ? 1 : fitScale)
            }
            /// create button tap effect
            .overlay {
                if !isPresented {
                    Capsule()
                        .foregroundStyle(.clear)
                        .frame(width: minimizedButtonSize.width, height: minimizedButtonSize.height)
                        .contentShape(.capsule)
                        .onTapGesture {
                            isPresented = true
                        }
                        .transition(.identity)
                }
            }
            .background {
                background
                    .frame(
                        width: isPresented ? nil : minimizedButtonSize.width,
                        height: isPresented ? nil : minimizedButtonSize.height
                    )
                    .compositingGroup()
                    /// create fading out with blur effect
                    .opacity(isPresented ? 0 : 1)
                    .blur(radius: isPresented ? 30 : 0)
            }
            .fixedSize()
            .frame(
                width: isPresented ? nil : minimizedButtonSize.width,
                height: isPresented ? nil : minimizedButtonSize.height
            )
            .animation(animation, value: isPresented)
    }
}

private struct CustomMenuButton: View {
    var title: String
    var symbol: String
    var action: () -> Void = {}
    @Binding var isPresented: Bool
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                Spacer(minLength: 0)
                Image(systemName: symbol)
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .opacity(isPresented ? 1 : 0)
            .background {
                ZStack {
                    Rectangle()
                        .fill(.primary)
                        .opacity(isPresented ? 0 : 1)
                    Rectangle()
                        .fill(.background)
                        .opacity(isPresented ? 1 : 0)
                }
                .clipShape(.capsule)
            }
        }
    }
}

private struct CustomMenuSectionButton: View {
    var symbol: String
    @Binding var isPresented: Bool

    var action: () -> Void = {}
    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .frame(width: .infinity, height: .infinity)
                .opacity(isPresented ? 1 : 0)
                .background {
                    ZStack {
                        Rectangle()
                            .fill(.primary)
                            .opacity(isPresented ? 0 : 1)
                        Rectangle()
                            .fill(.background)
                            .opacity(isPresented ? 1 : 0)
                    }
                    .clipShape(.capsule)
                }
        }
    }
}

#Preview {
    ExpandableMenuiOS26DemoView()
}
