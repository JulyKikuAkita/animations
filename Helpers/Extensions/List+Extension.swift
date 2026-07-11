//
//  List+Extension.swift
//  animation
//
//  Created on 7/11/26.

import SwiftUI

extension List {
    @ContentBuilder
    func morphingRefreshable(onRefresh: @escaping () async -> Void) -> some View {
        modifier(MorphingRefreshableModifier(onRefresh: onRefresh))
    }
}

extension ScrollView {
    @ContentBuilder
    func morphingRefreshable(onRefresh: @escaping () async -> Void) -> some View {
        modifier(MorphingRefreshableModifier(onRefresh: onRefresh))
    }
}

private struct MorphingRefreshableModifier: ViewModifier {
    var onRefresh: () async -> Void
    /// View Properties
    @State private var scrollProgress: CGFloat = 0
    @State private var isRefreshing: Bool = false
    @State private var isAnimating: Bool = false
    @State private var tintColor: Color = .gray
    @State private var isTintUpdateAvailable: Bool = false
    @Environment(\.scenePhase) private var scenePhase

    func body(content: Content) -> some View {
        content
            .background(RefreshControlTintUpdater(color: $tintColor) {
                isTintUpdateAvailable = $0
            })
            .compositingGroup()
            .overlay(alignment: .top) {
                GeometryReader {
                    let safeArea = $0.safeAreaInsets
                    /// iPhoneAirSafeAreaHeight is 68.0
                    let iPhoneAirSafeAreaHeightBuffer: CGFloat = 70.0

                    ZStack {
                        /// hide the morphing view when the safe area is interrupted by some other view e.g. navigation etc
                        if safeArea.top < iPhoneAirSafeAreaHeightBuffer, scrollProgress != 0 {
                            morphingView(safeArea)
                        }
                    }
                    .ignoresSafeArea()
                }
                .frame(height: 1)
                .allowsHitTesting(false)
            }
            .mask {
                Rectangle()
                    .ignoresSafeArea()
            }
            /// using native refreshable modifier and add custom view on top
            .refreshable {
                isRefreshing = true
                await onRefresh()
                isAnimating = true

                /// Reset scroll progress without waiting scroll geometry to fire
                withAnimation(.easeInOut(duration: 0.2), completionCriteria: .logicallyComplete) {
                    /// setting scroll progress to 0 will remove the view instantly
                    scrollProgress = 0.01
                } completion: {
                    scrollProgress = 0
                    isAnimating = false
                }
                isRefreshing = false
            }
            .onScrollGeometryChange(for: CGFloat.self) {
                $0.contentOffset.y + $0.contentInsets.top
            } action: { _, newValue in
                let progress = max(min(-newValue / 60, 1), 0)
                if !isAnimating {
                    scrollProgress = isRefreshing ? 1 : progress
                }
            }
    }

    private func morphingView(_ safeArea: EdgeInsets) -> some View {
        let hasDynamicIsland = safeArea.top >= 59
        let extraScrollOffset = hasDynamicIsland ? 0 : 15.0
        let scrollOffset = (safeArea.top < 35 ?
            (safeArea.top + 35 + 15) :
            (safeArea.top + extraScrollOffset)) * scrollProgress
        let blurRadius = 25.0

        return Rectangle()
            .fill(.clear)
            .frame(height: safeArea.top)
            .overlay(alignment: hasDynamicIsland ? .center : .top) {
                /// The fitting size will be 120,36, and since we'res using a smaller size will avoid view bleeding
                Capsule()
                    .fill(.black)
                    .frame(width: 100, height: 33)
                    .opacity(scenePhase == .active ? 1 : 0)
                    .mask {
                        Capsule()
                            .padding(.top, 5)
                    }
                    .overlay(alignment: .bottom) {
                        let indicatorSize = 30 + (scrollProgress * 10)
                        /// Indicator
                        Circle()
                            .fill(.black)
                            .frame(width: indicatorSize, height: indicatorSize)
                            .offset(y: scrollOffset)
                    }
                    .compositingGroup()
                    .blur(radius: blurRadius - (blurRadius * scrollProgress))
                    .visualEffect { [scrollProgress] content, proxy in
                        content
                            .layerEffect(
                                ShaderLibrary.alphaV2Threshold(),
                                maxSampleOffset: proxy.size,
                                isEnabled: scrollProgress != 1
                            )
                    }
                    .overlay(alignment: .bottom) {
                        let indicatorSize = 30 + (scrollProgress * 10)
                        let indicatorOpacity = scrollProgress > 0.8 ? (scrollProgress - 0.8) / 0.2 : 0

                        ProgressView()
                            .tint(.white)
                            .controlSize(.small)
                            .opacity(indicatorOpacity)
                            .frame(width: indicatorSize, height: indicatorSize)
                            .offset(y: scrollOffset)
                    }
                    .offset(y: safeArea.top < 35 ? -35 : 0)
            }
            .opacity(0.4)
    }
}

/// Updating refresh control tint color
private struct RefreshControlTintUpdater: UIViewRepresentable {
    @Binding var color: Color
    /// Fallback check
    var result: (Bool) -> Void
    func makeUIView(context _: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        updateTint(view)
        return view
    }

    func updateUIView(_ uiView: UIView, context _: Context) {
        updateTint(uiView)
    }

    private func updateTint(_ view: UIView) {
        DispatchQueue.main.async {
            if let compositingGroup = view.superview?.superview,
               let scrollview = compositingGroup.subviews.last?.subviews.last as? UIScrollView
            {
                scrollview.refreshControl?.tintColor = UIColor(color)
                result(true)
            } else {
                result(false)
            }
        }
    }
}
