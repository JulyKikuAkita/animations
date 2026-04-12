//
//  TransitionAnimationIOS26.swift
//  animation
//
//  Created on 4/11/26.
//
// Apple Store Transition Animation (Shared Element Transition)

import SwiftUI

struct AppleStoreSharedElementTransitionDemoView: View {
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
                    .frame(
                        width: animateContent ? nil : sourceRect.width,
                        height: animateContent ? config.detailCardHeight : sourceRect.height,
                    ).offset(
                        x: animateContent ? 0 : sourceRect.minX,
                        y: animateContent ? 0 : sourceRect.minY,
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .visualEffect { [animateContent] content, proxy in
                        let minY = proxy.frame(in: .scrollView).minY
                        let height = animateContent ? (proxy.size.height + 10) : 0

                        return content
                            .offset(y: -minY > height ? -(minY + height) : 0)
                            /// removing bouncing
                            .offset(y: minY > 0 ? -minY : 0)
                    }
                    .zIndex(1000)

                content(safeArea, dismiss)
            }
        }
        .background(.background)
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
        .scaleEffect(dragScale)
        .scaleEffect(buttonScale)
        .ignoresSafeArea()
        .gesture(
            BasedTransitionGesture {
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
        .opacity((dragScale - 0.95) / 0.05)
    }

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

private struct BasedTransitionGesture: UIGestureRecognizerRepresentable {
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

    /// We need to check if the gesture is to for scroll view
    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        func gestureRecognizer(
            _: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            /// disable scroll from top and only allow pan gesture to dismiss action
            if let scrollView = otherGestureRecognizer.view as? UIScrollView {
                let contentOffset = scrollView.contentOffset.y.rounded()

                /// safe value = 1, instead of 0
                return contentOffset <= 1
            }
            return false
        }

        /// check if zoom transition is enabled ? if so use the zoom transition (default) if not use the simple pan gesture
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let panGesture = gestureRecognizer as? UIPanGestureRecognizer else {
                return false
            }
            let velocity = panGesture.velocity(in: panGesture.view)
            /// optional slide gesture to dismiss the view
            let locationX = panGesture.location(in: panGesture.view).x
            return (velocity.y > abs(velocity.x)) || (locationX < 30)
        }
    }
}

#Preview {
    AppleStoreSharedElementTransitionDemoView()
}
