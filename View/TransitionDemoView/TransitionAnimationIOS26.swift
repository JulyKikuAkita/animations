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
                SharedElementTransitionHeroAnimation { isExpanded, dismiss in
                    Image(.fox)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .overlay {
                            if isExpanded {
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

private struct TransitoinConfig {
    var cardCornerRadius: CGFloat = 20
    var detailCornerRadius: CGFloat = 55
    var detailCardHeight: CGFloat = 460
    var animation: Animation = .smooth(duration: 0.3, extraBounce: 0)
}

struct SharedElementTransitionHeroAnimation<Hero: View, Content: View>: View {
    fileprivate var config: TransitoinConfig = .init()
    @ViewBuilder var hero: (_ isExpanded: Bool, _ dismiss: @escaping () -> Void) -> Hero
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
                    hero(false, dismiss)
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

    private func dismiss() {}
}

private struct TransitionFullScreenCover<Hero: View, Content: View>: View {
    var config: TransitoinConfig
    @Binding var buttonScale: CGFloat
    @Binding var showFullScreenCover: Bool
    @Binding var sourceRect: CGRect
    @ViewBuilder var hero: (_ isExpanded: Bool, _ dismiss: @escaping () -> Void) -> Hero
    @ViewBuilder var content: (_ safeArea: EdgeInsets, _ dismiss: @escaping () -> Void) -> Content
    /// View Properties
    @State private var animateContent: Bool = false
    @State private var safeArea: EdgeInsets = .init()
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
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .scaleEffect(buttonScale)
        .ignoresSafeArea()
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

    private func dismiss() {
        withAnimation(config.animation, completionCriteria: .removed) {
            animateContent = false
        } completion: {
            withoutAnimation {
                showFullScreenCover = false
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

#Preview {
    AppleStoreSharedElementTransitionDemoView()
}
