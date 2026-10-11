//
//  CustomContextMenu+iOS27.swift
//  animation
//
//  Created on 10/9/26.
//  Pinterest style
//
// Demo — Pinterest-style radial context menu: long-press a card, the
// background dims around it, action bubbles fan out from the finger, and
// sliding onto a bubble + lifting the finger triggers that action.
//
// Learning points
// ───────────────────────────────────────────────────────────────────────
// 1. One continuous touch drives everything.
//    `UILongPressGesture` (see LongPressGesture.swift) reports the press
//    location (`anchorLocation`, where the menu fans out) and keeps
//    streaming the finger (`pointingLocation`, used for hit-testing). The
//    menu is presented in a `fullScreenCover`, yet the gesture on the
//    source view keeps tracking because the touch started before it.
//
// 2. Everything in `.global` space.
//    The source rect (`onGeometryChange` → `.frame(in: .global)`), each
//    bubble's rect, and the gesture location all use global coordinates,
//    so a full-screen overlay (`.ignoresSafeArea()`) can compare them
//    directly with `CGRect.contains`.
//
// 3. Cut-out background with `.blendMode(.destinationOut)`.
//    `presentationBackground` is a dimmed rectangle masked by a shape that
//    punches a hole at the source view's rect. The source shrink/rotate is
//    replayed on the hole so the real card underneath stays visible and
//    in sync. `.compositingGroup()` on the source keeps the scale/rotation
//    applied as one layer.
//
// 4. Radial layout math.
//    Bubbles sit on a circle of radius `distance` around the anchor. The
//    angle between neighbours is the chord formula `2·asin(c / 2r)` where
//    the chord `c = itemSize + gap`, so bubbles never overlap. `baseAngle`
//    flips the fan to 0° or 180° depending on which half of the screen the
//    finger is in, and the anchor is clamped with padding so the fan stays
//    on screen. Inner `-rotation` keeps each icon upright after the outer
//    rotation positions it.
//
// 5. Selection + action on release.
//    `ActionView` is "active" when the finger is inside its rect. A short
//    `isInitialAnimationComplete` delay prevents the bubble under the
//    initial press from activating while it's still flying out.
//    `.sensoryFeedback(.selection, trigger:) { $1 }` buzzes only on
//    becoming active. The action runs when `showMenu` flips true → false
//    (finger lifted) while that bubble is active.
//
// 6. Present/dismiss without the slide-up.
//    `.navigationTransition(.crossFade)` replaces the default cover
//    animation; `onAppear` kicks off the bubble spring and source shrink.
// ───────────────────────────────────────────────────────────────────────

import SwiftUI

@available(iOS 27.0, *)
struct CustomContextMenuIOS27Demo: View {
    var body: some View {
        ScrollView(.vertical) {
            VStack {
                RoundedRectangle(cornerRadius: 30)
                    .fill(.gray)
                    .frame(height: 200)
                    .customContextMenu(containerRadius: 30) {
                        CustomAction(symbol: "square.and.arrow.up") {}

                        CustomAction(symbol: "pin") {}

                        CustomAction(symbol: "suit.heart") {}
                    }

                HStack {
                    RoundedRectangle(cornerRadius: 30)
                        .fill(.blue)
                        .frame(height: 200)

                    RoundedRectangle(cornerRadius: 30)
                        .fill(.yellow)
                        .frame(height: 200)
                }
            }
            .padding()
        }
    }
}

private struct CustomAction {
    var symbol: String
    var action: () -> Void
}

private struct Config {
    var viewRect: CGRect = .zero
    var shrinkSource: Bool = false
    var showMenu: Bool = false
    var animateMenu: Bool = false
    var anchorLocation: CGPoint?
    var pointingLocation: CGPoint?
}

@available(iOS 27.0, *)
private struct CustomContextMenu: ViewModifier {
    var containerRadius: CGFloat
    var actions: [CustomAction]
    /// View Properties
    @State private var config: Config = .init()
    func body(content: Content) -> some View {
        content
            .compositingGroup()
            .scaleEffect(config.shrinkSource ? 0.9 : 1)
            .rotationEffect(.init(degrees: config.shrinkSource ? 2 : 0))
            .onGeometryChange(for: CGRect.self) {
                $0.frame(in: .global)
            } action: { newValue in
                config.viewRect = newValue
            }
            .gesture(
                UILongPressGesture { initialLocation in
                    config.anchorLocation = initialLocation
                    config.pointingLocation = initialLocation
                    config.showMenu = true
                } onChange: { location in
                    config.pointingLocation = location
                } onEnd: {
                    config.showMenu = false
                    config.animateMenu = false
                    withAnimation(.easeInOut(duration: 0.25)) {
                        config.shrinkSource = false
                    }
                }
            )
            .fullScreenCover(isPresented: $config.showMenu) {
                ActionsView(config: $config, actions: actions)
                    .presentationBackground {
                        Rectangle()
                            .fill(.windowBackground.opacity(0.75))
                            .mask {
                                // masked background to show source view
                                let shrinkSource = config.shrinkSource
                                let viewRect = config.viewRect

                                Rectangle()
                                    .overlay(alignment: .topLeading) {
                                        RoundedRectangle(cornerRadius: containerRadius)
                                            .frame(width: viewRect.width, height: viewRect.height)
                                            .scaleEffect(shrinkSource ? 0.9 : 1)
                                            .rotationEffect(.init(degrees: shrinkSource ? 2 : 0))
                                            .offset(x: viewRect.minX, y: viewRect.minY)
                                            .blendMode(.destinationOut)
                                    }
                            }
                    }
                    .navigationTransition(.crossFade)
                    .onAppear {
                        withAnimation(.bouncy(duration: 0.35, extraBounce: 0.1)) {
                            config.animateMenu = true
                        }
                        withAnimation(.easeInOut(duration: 0.25)) {
                            config.shrinkSource = true
                        }
                    }
                    .onDisappear {
                        config.pointingLocation = nil
                        config.anchorLocation = nil
                    }
            }
    }
}

private struct ActionsView: View {
    @Binding var config: Config
    var actions: [CustomAction]
    var body: some View {
        GeometryReader {
            let containerSize = $0.size
            let containerRect = CGRect(origin: .zero, size: containerSize)
            // Customization Properties
            let itemSize: CGFloat = 55
            let distance: CGFloat = 80
            let gap: CGFloat = 20
            // Horizontal and Vertical Padding
            let count = CGFloat(actions.count)
            let horizontalPadding: CGFloat = 40
            let verticalTopPadding: CGFloat = ((count * itemSize) / 2) + 80
            let verticalBottomPadding: CGFloat = ((count * itemSize) / 2) + 30

            let anchorLocation = config.anchorLocation ?? .zero
            let anchor = CGPoint(
                x: min(max(anchorLocation.x, horizontalPadding), containerSize.width - horizontalPadding),
                y: min(max(anchorLocation.y, verticalTopPadding), containerSize.height - verticalBottomPadding)
            )
            let baseAngle: CGFloat = anchor.x < containerRect.midX ? 0 : 180
            let stepDistance = min((itemSize + gap) / (2 * distance), 1)
            let step = 2 * asin(stepDistance) * 180 / .pi

            ZStack {
                ForEach(actions.indices, id: \.self) { index in
                    let action = actions[index]
                    let rotation = baseAngle + (CGFloat(index) - (count - 1) / 2) * step

                    ActionView(
                        action: action,
                        location: $config.pointingLocation,
                        showMenu: $config.showMenu
                    )
                    .rotationEffect(.degrees(-rotation))
                    .frame(width: itemSize, height: itemSize)
                    .shadow(color: .black.opacity(0.2), radius: 5)
                    .offset(x: config.animateMenu ? distance : 0)
                    .rotationEffect(.degrees(rotation))
                }
            }
            .compositingGroup()
            .opacity(config.animateMenu ? 1 : 0)
            .visualEffect { content, proxy in
                content
                    .offset(
                        x: anchor.x - proxy.size.width / 2,
                        y: anchor.y - proxy.size.height / 2
                    )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .ignoresSafeArea()
    }
}

@resultBuilder private struct CustomActionBuilder {
    static func buildBlock(_ components: CustomAction...) -> [CustomAction] {
        components
    }
}

@available(iOS 27.0, *)
private extension View {
    func customContextMenu(
        containerRadius: CGFloat,
        @CustomActionBuilder actions: () -> [CustomAction]
    ) -> some View {
        modifier(
            CustomContextMenu(
                containerRadius: containerRadius,
                actions: actions()
            )
        )
    }
}

private struct ActionView: View {
    var action: CustomAction
    @Binding var location: CGPoint?
    @Binding var showMenu: Bool
    /// View Properties
    @State private var viewRect: CGRect = .zero
    @State private var isInitialAnimationComplete: Bool = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let isActive = viewRect.contains(location ?? .zero) && isInitialAnimationComplete
        let activeColor = colorScheme == .dark ? Color.black : Color.white

        Image(systemName: action.symbol)
            .font(.title2)
            .foregroundStyle(isActive ? activeColor : Color.primary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(isActive ? Color.primary : activeColor, in: .circle)
            .scaleEffect(isActive ? 1.3 : 1)
            .animation(.easeInOut(duration: 0.15), value: isActive)
            .onGeometryChange(for: CGRect.self) {
                $0.frame(in: .global)
            } action: { newValue in
                viewRect = newValue
            }
            .sensoryFeedback(.selection, trigger: isActive) { $1 }
            .onChange(of: showMenu) { oldValue, newValue in
                guard !newValue, oldValue, isActive else { return }
                action.action()
            }
            .task {
                try? await Task.sleep(for: .seconds(0.15))
                isInitialAnimationComplete = true
            }
    }
}

@available(iOS 27.0, *)
#Preview {
    CustomContextMenuIOS27Demo()
}
