//
//  StaggeredAnimationView.swift
//  animation
//
//  Learning point
//  ──────────────
//  Cascade reveal: when a list/grid appears, items animate in one
//  at a time with a per-item delay (item 0 at 0s, item 1 at 0.04s,
//  item 2 at 0.08s, etc) — the iOS-classic "wave-in" feel. Built on
//  a custom `Transition` whose body reads the index of each
//  subview and bakes a delay into the animation.
//
//  Three reusable mechanics
//  ────────────────────────
//    1. **Custom `Transition` with index-aware delay** —
//       `CustomStaggeredTransition` takes an `index: Int` parameter
//       and applies `.animation(config.animation.delay(index * 0.04))`.
//       Each subview computes its own delay; SwiftUI sequences them
//       automatically as their `phase` transitions
//       `.willAppear → .identity` and `.didDisappear`.
//    2. **`Group(subviews: content) { collection in ... }`** (iOS 18) —
//       lets the wrapper iterate over its declared children with
//       indices. Each child gets its own `transition(...)` with the
//       right index. Without iOS 18, you'd have to enumerate via
//       `ForEach(0..<count)` at the call site.
//    3. **Asymmetric appear/disappear control** —
//       `disappearInSameDirection` / `noDisappearAnimation` flags
//       let callers customise the exit. By default items DISAPPEAR in
//       the OPPOSITE direction from their entry (more interesting
//       visually); flip the flag for symmetric "rewind" behaviour.
//
//  Three properties animated together
//  ──────────────────────────────────
//  Each item gets `opacity` + `blur` + `scaleEffect` + `offset`
//  during its non-identity phase, all animated together via the
//  same delayed `.animation(...)` modifier:
//
//      .opacity(isIdentity ? 1 : 0)
//      .blur(radius: isIdentity ? 0 : config.blurRadius)
//      .scaleEffect(isIdentity ? 1 : config.scale, anchor: config.scaleAnchor)
//      .offset(x: offsetX, y: offsetY)
//      .animation(config.animation.delay(animationDelay), value: phase)
//
//  Combined: items ENTER from a translated, scaled-down, blurred,
//  invisible state and SETTLE into their final position with a
//  springy decay.
//
//  Why `compositingGroup` before opacity/blur
//  ──────────────────────────────────────────
//  Without `compositingGroup`, opacity and blur would apply to each
//  leaf inside the subview separately — text + icon would blur
//  independently, and the seams would show. With it, the entire
//  subview is flattened to one layer first; opacity and blur then
//  apply to the unified layer. Cleaner visual.
//
//  Why `min(index * config.delay, config.maxDelay)`
//  ────────────────────────────────────────────────
//  In a long list (say 50 items), per-item delay would push the
//  last item past 2 seconds — long enough that it feels broken.
//  Capping at `maxDelay` (default 0.3s) means the last few items
//  ALL appear together at the cap; subjectively reads as "wave
//  hits the bottom" rather than "view stalled."
//
//  Key APIs
//  ────────
//  • `Transition` (iOS 17+) — declarative custom transitions
//    with access to `TransitionPhase`.
//  • `Group(subviews: content) { collection in ForEach(collection.indices) }` —
//    introspect declared children.
//  • `Animation.delay(_:)` — per-element offset on a shared curve.
//  • `TransitionPhase.identity / .didDisappear / .willAppear` —
//    state machine of the transition.
//
//  How to apply
//  ────────────
//  Drop `StaggeredAnimationView { ... }` around any list/grid that
//  benefits from a wave-in. Typical use cases: notification feeds,
//  search results, dashboard widgets, onboarding cards. Pair with
//  `.animation(...).animation(.smooth, value: showList)` at the
//  call site to drive the cascade from a Bool flip.
//
//  See also
//  ────────
//  • View/Sheet/iOS26OnBoardingSheet.swift — uses a similar
//    cascade idea but with a manual `await Task.sleep` loop driving
//    multiple `@State` flags rather than a custom Transition.
//
import SwiftUI

struct StaggeredAnimationDemoView: View {
    @State private var showList: Bool = false
    @State private var showGrid: Bool = false
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    HStack {
                        Button("Toggle List") {
                            showList.toggle()
                        }

                        Spacer(minLength: 0)

                        Button("Toggle Grid") {
                            showGrid.toggle()
                        }
                    }

                    if showList {
                        let config = StaggeredConfig(
                            offset: .init(width: 150, height: 50),
                            scale: 0.85,
                            scaleAnchor: .center
                        )

                        ForEach(1 ... 7, id: \.self) { _ in
                            StaggeredAnimationView(config: config) {
                                dummyListView()
                            }
                        }
                    }

                    if showGrid {
                        LazyVGrid(columns: Array(repeating: GridItem(), count: 2)) { StaggeredAnimationView {
                            ForEach(1 ... 6, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(.black.gradient)
                                    .frame(height: 150)
                            }
                        }
                        }
                    }

                    Spacer(minLength: 0)
                }
                .padding(15)
                // width of the view should be constant even when no view is present
                // for the staggered animation
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("Staggered Animation")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    func dummyListView() -> some View {
        HStack(spacing: 10) {
            Circle()
                .frame(width: 45, height: 45)

            VStack(alignment: .leading, spacing: 5) {
                RoundedRectangle(cornerRadius: 5)
                    .frame(height: 10)
                    .padding(.trailing, 20)

                RoundedRectangle(cornerRadius: 5)
                    .frame(height: 10)
                    .padding(.trailing, 140)

                RoundedRectangle(cornerRadius: 5)
                    .frame(width: 100, height: 10)
            }
        }
    }
}

// work with scrollView, grid etc
struct StaggeredAnimationView<Content: View>: View {
    var config: StaggeredConfig = .init()
    @ViewBuilder var content: Content
    var body: some View {
        Group(subviews: content) { collection in
            ForEach(collection.indices, id: \.self) { index in
                collection[index]
                    .transition(CustomStaggeredTransition(index: index, config: config))
            }
        }
    }
}

private struct CustomStaggeredTransition: Transition {
    var index: Int
    var config: StaggeredConfig
    func body(content: Content, phase: TransitionPhase) -> some View {
        let animationDelay: Double = min(Double(index) * config.delay, config.maxDelay)

        let isIdentity: Bool = phase == .identity
        let didDisappear: Bool = phase == .didDisappear
        let posX: CGFloat = config.offset.width
        let posY: CGFloat = config.offset.height

        let reverseX: CGFloat = config.disappearInSameDirection ? posX : -posX
        let disabledX: CGFloat = config.noDisappearAnimation ? 0 : reverseX

        let reverseY: CGFloat = config.disappearInSameDirection ? posY : -posY
        let disabledY: CGFloat = config.noDisappearAnimation ? 0 : reverseY

        let offsetX = isIdentity ? 0 : didDisappear ? disabledX : posX
        let offsetY = isIdentity ? 0 : didDisappear ? disabledY : posY

        content
            .opacity(isIdentity ? 1 : 0)
            .blur(radius: isIdentity ? 0 : config.blurRadius)
            .compositingGroup()
            .scaleEffect(isIdentity ? 1 : config.scale, anchor: config.scaleAnchor)
            .offset(x: offsetX, y: offsetY)
            .animation(config.animation.delay(animationDelay), value: phase)
    }
}

struct StaggeredConfig {
    var delay: Double = 0.04
    var maxDelay: Double = 0.3
    var blurRadius: CGFloat = 6
    var offset: CGSize = .init(width: 0, height: 100)
    var scale: CGFloat = 0.95
    var scaleAnchor: UnitPoint = .center
    var animation: Animation = .smooth(duration: 0.3, extraBounce: 0)
    var disappearInSameDirection: Bool = false
    var noDisappearAnimation: Bool = false
}

#Preview {
    StaggeredAnimationDemoView()
}
