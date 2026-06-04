//
//  TransitionAnimationIOS26.swift
//  animation
//
//  Created on 4/11/26.
//
//  Learning point
//  ──────────────
//  Apple-Store-style hero card → fullscreen detail transition.
//  Tap a card; it press-shrinks slightly, the cover materialises
//  AT THE CARD's exact frame, then expands to fullscreen with the
//  hero pinning to the top as the user scrolls. Drag down (or
//  edge-swipe from left) to dismiss back to the card. THIS is the
//  cinematic transition iOS uses for the App Store today, App
//  Store games, and several Apple promotional carousels.
//
//  The architecture: NOT `matchedTransitionSource`
//  ───────────────────────────────────────────────
//  iOS 18 ships `matchedTransitionSource` + `.navigationTransition(.zoom(...))`
//  for simpler hero animations, but it's limited: only works
//  through `NavigationLink`, can't be combined with custom
//  scroll/pan dismissal, and the source frame must be a
//  rectangle. This file uses `.fullScreenCover` instead and
//  drives the hero MANUALLY via `sourceRect` + `animateContent`
//  flag — giving full control over enter, scroll-pin, drag-to-
//  dismiss, and any visual effect we want.
//
//  Six pieces working together
//  ───────────────────────────
//    1. **`sourceRect: CGRect`** — read from the source button via
//       `onGeometryChange(for: CGRect.self) { $0.frame(in: .global) }`.
//       This is THE coordinate the cover uses to position the hero
//       so it materialises exactly over the card.
//    2. **`animateContent: Bool`** — flips `false → true` inside a
//       `.task { withAnimation { ... } }` once the cover appears.
//       Drives EVERY visual transform: hero frame, hero offset,
//       mask shape, mask offset, dismiss button position.
//    3. **Inner-frame + outer-alignment pattern** —
//          .frame(width/height: collapsed-or-expanded values)
//          .offset(x/y: sourceRect.minX/Y or 0)
//          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
//       Inner frame sets the hero's own size; offset positions it
//       at the source rect; outer .infinity-frame creates a
//       full-screen container so the offset is interpreted in
//       SCREEN coords. This pattern repeats for the mask, the
//       dismiss button, and any UI that needs to track the hero.
//    4. **Sticky header via `visualEffect`** — once expanded, the
//       hero pins to the top during scroll using:
//          let minY = proxy.frame(in: .scrollView).minY
//          .offset(y: -minY > height ? -(minY + height) : 0)
//          .offset(y: minY > 0 ? -minY : 0)
//       Two stacked offsets: pin past `height`, prevent overscroll
//       bounce.
//    5. **Custom UIPanGestureRecognizer for dismiss** — bridged via
//       `UIGestureRecognizerRepresentable` (iOS 18+). The delegate
//       allows simultaneous gestures only when the scrollView is
//       at the top (`contentOffset.y <= 1`), and starts on
//       VERTICAL drag-down OR a left-edge slide (< 30pt from
//       leading). Both behaviours combined are why this is
//       file-private — neither alone is reusable.
//    6. **Two stacked `.scaleEffect`s** — `dragScale` (interactive
//       drag feedback) and `buttonScale` (matching the source
//       button's press-down keyframe). Layered, so a press during
//       drag still scales naturally.
//
//  The press-down handoff
//  ──────────────────────
//  When the user taps the card, `SharedElementTransitionButtonStyle`
//  applies a `KeyframeAnimator` that scales the button to 0.95
//  while pressed. The cover's `buttonScale` (read live via
//  `onGeometryChange` on the button's frame) tracks this. So the
//  cover materialises AT 0.95 scale, exactly matching the card's
//  pressed state. Releases ease back to 1.0 in lockstep with the
//  button. Without this, the cover would visibly "snap" to a
//  different scale on appearance.
//
//  Why `withoutAnimation { showFullScreenCover = true }` (and again on dismiss)
//  ───────────────────────────────────────────────────────────────────────────
//  iOS's `.fullScreenCover` ships with its own default fade
//  animation. We don't want that — we want the cover to
//  materialise INSTANTLY at the card's frame and then animate
//  the hero/expansion ourselves via `animateContent`. The
//  `withoutAnimation` helper (project utility) wraps the state
//  toggle in a `Transaction(disablesAnimations: true)` to skip
//  the system fade.
//
//  Why `completionCriteria: .removed` on dismiss animation
//  ───────────────────────────────────────────────────────
//      withAnimation(config.animation, completionCriteria: .removed) {
//          dragScale = 1; animateContent = false
//      } completion: {
//          withoutAnimation { showFullScreenCover = false }
//      }
//  `.removed` (iOS 18+) fires the completion only AFTER any
//  removal transition finishes — including the hero collapsing
//  back into the card. Using `.logicallyComplete` would dismiss
//  the cover before the hero finished collapsing, leaving a
//  visible discontinuity.
//
//  Key APIs
//  ────────
//  • `.fullScreenCover` + `withoutAnimation` — opt out of system
//    cover fade for hand-controlled transitions.
//  • `.onGeometryChange(for: CGRect.self) { $0.frame(in: .global) }` —
//    track source frame.
//  • Custom `ButtonStyle` with `keyframeAnimator(trigger: configuration.isPressed)` —
//    press-down keyframe.
//  • `UIGestureRecognizerRepresentable` (iOS 18+) — bridge custom
//    UIKit gestures into SwiftUI.
//  • `withAnimation(_, completionCriteria: .removed)` — fire
//    completion after removal transitions finish.
//  • `visualEffect { content, proxy in ... }` — sticky header
//    via scroll-frame offsets.
//
//  How to apply
//  ────────────
//  Reach for this template whenever you need a CINEMATIC card →
//  fullscreen reveal that survives complex scroll behaviour:
//  product detail pages, video preview → playback, gallery
//  zoom-in. The "inner-frame + offset + outer-alignment"
//  pattern is the architectural lesson, useful for any UI that
//  needs to track another view's screen position during
//  animation.
//
//  See also
//  ────────
//  • RippleTransitionDemoView.swift — shader-driven transition
//    (different category).
//  • View/Sheet/iOS26ResizingSheet.swift — sibling sticky-header
//    pattern using `CADisplayLink` for layer-presentation Y reads.
//  • View/Video/ZoomTransitionView.swift — built-in
//    `.zoom(sourceID:in:)` for simpler list → detail flows.
//

import SwiftUI

struct AppleStoreSharedElementTransitionDemo: View {
    var body: some View {
        NavigationStack {
            VStack {
                SharedElementTransitionHeroAnimation { _, dismiss in
                    Image(.fox)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .overlay {
                            if let dismiss {
                                Rectangle()
                                    .foregroundStyle(.clear)
                                    .contentShape(.rect)
                                    .onTapGesture {
                                        dismiss()
                                    }
                                    .transition(.identity)
                            }
                        }
                } content: { _, dismiss in
                    Color.orange
                        .frame(height: 1900)
                        .contentShape(.rect)
                        .onTapGesture {
                            dismiss()
                        }
                }
                .frame(height: 415)

                Spacer()
            }
            .padding(.horizontal, 25)
            .padding(.vertical, 15)
            .navigationTitle("Apple Store Transition")
        }
    }
}

private struct TransitionConfig {
    var cardCornerRadius: CGFloat = 20
    var detailCornerRadius: CGFloat = 55
    var detailCardHeight: CGFloat = 460
    var animation: Animation = .smooth(duration: 0.3, extraBounce: 0)
}

struct SharedElementTransitionHeroAnimation<Hero: View, Content: View>: View {
    fileprivate var config: TransitionConfig = .init()
    @ViewBuilder var hero: (_ isExpanded: Bool, _ dismiss: (() -> Void)?) -> Hero
    @ViewBuilder var content: (_ safeArea: EdgeInsets, _ dismiss: @escaping () -> Void) -> Content
    /// View properties
    @State private var showFullScreenCover: Bool = false
    @State private var sourceRect: CGRect = .zero
    @State private var buttonScale: CGFloat = 1

    var body: some View {
        Button {
            withoutAnimation {
                showFullScreenCover = true
            }
        } label: {
            Rectangle()
                .foregroundStyle(.clear)
                .overlay {
                    if !showFullScreenCover {
                        hero(false, nil)
                    }
                }
                .clipShape(.rect(cornerRadius: config.cardCornerRadius))
                .contentShape(.rect(cornerRadius: config.cardCornerRadius))
                /// Track the button's current frame to compute buttonScale.
                /// When the button animates a press-down (via keyframe), its frame shrinks,
                /// so buttonScale < 1. The full-screen cover applies this same scale
                /// so it appears to emerge from the pressed-down card seamlessly.
                .onGeometryChange(for: CGRect.self, of: {
                    $0.frame(in: .global)
                }, action: { newValue in
                    buttonScale = newValue.width / sourceRect.width
                })
        }
        .buttonStyle(SharedElementTransitionButtonStyle())
        .onGeometryChange(for: CGRect.self, of: {
            $0.frame(in: .global)
        }, action: { newValue in
            sourceRect = newValue
        })
        .fullScreenCover(isPresented: $showFullScreenCover) {
            TransitionFullScreenCover(
                config: config,
                buttonScale: $buttonScale,
                showFullScreenCover: $showFullScreenCover,
                sourceRect: $sourceRect,
                hero: hero,
                content: content
            )
        }
    }
}

private struct TransitionFullScreenCover<Hero: View, Content: View>: View {
    var config: TransitionConfig
    @Binding var buttonScale: CGFloat
    @Binding var showFullScreenCover: Bool
    @Binding var sourceRect: CGRect
    @ViewBuilder var hero: (_ isExpanded: Bool, _ dismiss: (() -> Void)?) -> Hero
    @ViewBuilder var content: (_ safeArea: EdgeInsets, _ dismiss: @escaping () -> Void) -> Content
    /// View Properties
    @State private var animateContent: Bool = false
    @State private var isHorizontalSwipe: Bool = false
    @State private var safeArea: EdgeInsets = .init()
    @State private var dragScale: CGFloat = 1
    var body: some View {
        let cornerRadius: CGFloat = animateContent ? config.detailCornerRadius : config.cardCornerRadius
        ScrollView(.vertical) {
            VStack(spacing: 0) {
                Rectangle()
                    .foregroundStyle(.clear)
                    .overlay {
                        hero(animateContent, dismiss)
                    }
                    /// Inner frame: sets the hero's own size.
                    /// - Collapsed: matches the source card's exact size on screen.
                    /// - Expanded: width = nil (fills parent), height = detailCardHeight.
                    .frame(
                        width: animateContent ? nil : sourceRect.width,
                        height: animateContent ? config.detailCardHeight : sourceRect.height,
                    )
                    /// Offset positions the hero at the source card's screen coordinates when collapsed,
                    /// and at the natural origin (0,0) when expanded.
                    .offset(
                        x: animateContent ? 0 : sourceRect.minX,
                        y: animateContent ? 0 : sourceRect.minY,
                    )
                    /// Outer frame: creates a full-screen container aligned to topLeading.
                    /// This gives the inner frame + offset a coordinate space to work in:
                    /// the hero is placed relative to the top-left corner of the screen,
                    /// so sourceRect.minX/minY produce pixel-perfect positioning over the original card.
                    /// When animating to expanded, the hero grows to fill this full-screen container.
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    /// Sticky header effect: keeps the hero pinned at the top while scrolling.
                    .visualEffect { [animateContent] content, proxy in
                        let minY = proxy.frame(in: .scrollView).minY
                        /// Only apply sticky behavior when expanded; height acts as the "pin threshold".
                        let height = animateContent ? (proxy.size.height + 10) : 0

                        return content
                            /// Pin the hero when scrolled past its height (sticky header).
                            .offset(y: -minY > height ? -(minY + height) : 0)
                            /// Prevent overscroll bounce from pulling the hero downward.
                            .offset(y: minY > 0 ? -minY : 0)
                    }
                    .zIndex(1000)

                content(safeArea, dismiss)
            }
        }
        .background(.background)
        /// Mask clips the entire scroll view to the card shape when collapsed,
        /// then expands to full screen when animateContent is true.
        /// Uses the same inner-frame + offset + outer-alignment pattern as the hero
        /// so the visible region exactly matches the card's position during the transition.
        .mask(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: cornerRadius)
                .frame(
                    width: animateContent ? nil : sourceRect.width,
                    height: animateContent ? nil : sourceRect.height,
                ).offset(
                    x: animateContent ? 0 : sourceRect.minX,
                    y: animateContent ? 0 : sourceRect.minY,
                )
        }
        /// Dismiss button overlay: positioned to track the hero area.
        /// Uses the same frame+offset pattern so the button stays anchored
        /// to the top-trailing corner of the hero during the transition.
        .overlay(alignment: .topLeading) {
            dismissButton()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .frame(
                    width: animateContent ? nil : sourceRect.width,
                    height: animateContent ? config.detailCardHeight : sourceRect.height,
                ).offset(
                    x: animateContent ? 0 : sourceRect.minX,
                    y: animateContent ? safeArea.top : sourceRect.minY,
                )
        }
        /// Two independent scale effects layered together:
        /// - dragScale: shrinks the view during a dismiss drag gesture (interactive feedback).
        /// - buttonScale: matches the press-down animation of the source button,
        ///   so the cover appears at the same scale the button was when tapped.
        .scaleEffect(dragScale)
        .scaleEffect(buttonScale)
        .ignoresSafeArea()
        .gesture(
            TransitionDismissPanGesture {
                handleGesture($0)
            }
        )
        .onGeometryChange(for: EdgeInsets.self) {
            $0.safeAreaInsets
        } action: { newValue in
            safeArea = newValue
        }
        .task {
            guard !animateContent else { return }
            withAnimation(config.animation) {
                animateContent = true
            }
        }
        .presentationBackground {
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(animateContent ? 1 : 0)
        }
    }

    private func dismissButton() -> some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .frame(width: 20, height: 30)
                .contentShape(.circle)
        }
        .buttonStyle(PlainButtonStyle()) // or glass
        .padding(.trailing, 15)
        .animation(.linear(duration: 0.15)) {
            $0.opacity(animateContent ? 1 : 0)
        }
        /// Fade out the dismiss button proportionally as the drag progresses.
        /// dragScale ranges from 1.0 (no drag) to ~0.8 (full drag).
        /// This maps dragScale 1.0 -> opacity 1.0, dragScale 0.95 -> opacity 0.0.
        .opacity((dragScale - 0.95) / 0.05)
    }

    /// Animate the detail view back to the card position, then dismiss the cover.
    /// completionCriteria: .removed ensures the completion fires after the view
    /// finishes its removal transition (not just when the animation ends).
    private func dismiss() {
        withAnimation(config.animation, completionCriteria: .removed) {
            dragScale = 1
            animateContent = false
        } completion: {
            withoutAnimation {
                showFullScreenCover = false
            }
        }
    }

    private func handleGesture(_ gesture: UIPanGestureRecognizer) {
        let state = gesture.state
        let translationX = gesture.translation(in: gesture.view).x * 1.2
        let translationY = gesture.translation(in: gesture.view).y
        let translation = isHorizontalSwipe ? translationX : translationY

        if state == .began {
            isHorizontalSwipe = gesture.location(in: gesture.view).x < 30
        }
        if state == .began || state == .changed {
            // TODO: have a helper to simply the max/min syntax
            let progress = max(min(translation / config.detailCardHeight, 1), 0)
            dragScale = 1 - (progress * 0.2)
        } else {
            isHorizontalSwipe = false

            if dragScale < 0.9 {
                dismiss()
            } else {
                withAnimation(config.animation) {
                    dragScale = 1
                }
            }
        }
    }
}

private struct SharedElementTransitionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .keyframeAnimator(initialValue: 1.0, trigger: configuration.isPressed) { content, scale in
                content
                    .scaleEffect(scale)
            } keyframes: { _ in
                if configuration.isPressed {
                    CubicKeyframe(0.95, duration: 0.15)
                } else {
                    CubicKeyframe(1, duration: 0.15)
                }
            }
    }
}

/// Private: combines three specialized delegate behaviors for the shared element transition dismiss:
/// Cannot be generalized because:
/// 1. shouldRecognizeSimultaneouslyWith: only allows gesture when scroll view is at top (contentOffset <= 1)
/// 2. gestureRecognizerShouldBegin: activates on vertical swipe down OR left-edge swipe (x < 30pt)
/// The left-edge swipe + scroll-top detection combo is specific to this Apple Store card transition.
private struct TransitionDismissPanGesture: UIGestureRecognizerRepresentable {
    var handle: (UIPanGestureRecognizer) -> Void

    func makeCoordinator(converter _: CoordinateSpaceConverter) -> Coordinator {
        Coordinator()
    }

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let gesture = UIPanGestureRecognizer()
        gesture.delegate = context.coordinator
        return gesture
    }

    func updateUIGestureRecognizer(
        _: UIPanGestureRecognizer,
        context _: Context
    ) {}

    func handleUIGestureRecognizerAction(
        _ recognizer: UIPanGestureRecognizer,
        context _: Context
    ) {
        handle(recognizer)
    }

    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        /// Only recognize simultaneously when the scroll view is at the top,
        /// so scrolling content takes priority over the dismiss gesture.
        func gestureRecognizer(
            _: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            if let scrollView = otherGestureRecognizer.view as? UIScrollView {
                let contentOffset = scrollView.contentOffset.y.rounded()
                return contentOffset <= 1
            }
            return false
        }

        /// Activate for vertical swipe down OR left-edge slide (< 30pt from left).
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let panGesture = gestureRecognizer as? UIPanGestureRecognizer else {
                return false
            }
            let velocity = panGesture.velocity(in: panGesture.view)
            let locationX = panGesture.location(in: panGesture.view).x
            return (velocity.y > abs(velocity.x)) || (locationX < 30)
        }
    }
}

#Preview {
    AppleStoreSharedElementTransitionDemo()
}
