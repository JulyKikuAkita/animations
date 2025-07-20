//
//  PullEffectScrollView.swift
//  animation
//
//  Created on 7/20/25.

import SwiftUI

struct PullEffectScrollViewDemo: View {
    var body: some View {
        GeometryReader { proxy in
            let safeAreaInset = proxy.safeAreaInsets

            NavigationStack {
                PullEffectScrollView(
                    actionTopPadding: safeAreaInset.top + 35,
                    leadingAction: .init(symbol: "plus", action: {}),
                    centerAction: .init(symbol: "arrow.clockwise.circle", action: {}),
                    trailingAction: .init(symbol: "xmark", action: {})
                ) {
                    DummyGridView(rowCount: 2, gridCount: 8, tint: .orange)
                }
                .navigationBarTitleDisplayMode(.inline)
                .navigationTitle("iOS 26 PullEffectScrollView Demo")
            }
        }
    }
}

struct PullEffectScrollView<Content: View>: View {
    var dragDistance: CGFloat = 100
    var actionTopPadding: CGFloat = 0
    var leadingAction: PullEffectAction
    var centerAction: PullEffectAction
    var trailingAction: PullEffectAction
    @ViewBuilder var content: Content

    /// View Properties
    @State private var effectProgress: CGFloat = 0
    @GestureState private var isGestureActive: Bool = false
    @State private var scrollOffset: CGFloat = 0
    @State private var initialScrollOffset: CGFloat?
    @State private var activePositon: ActionPosition?
    @State private var hapticTrigger: Bool = false
    @State private var scaleEffect: Bool = false
    @Namespace private var animation
    var body: some View {
        ScrollView(.vertical) {
            content
        }
        .onScrollGeometryChange(for: CGFloat.self, of: {
            $0.contentOffset.y + $0.contentInsets.top
        }, action: { _, newValue in
            scrollOffset = newValue
        })
        /// Storing initial scroll offset when drag gesture is active
        .onChange(of: isGestureActive) { _, newValue in
            initialScrollOffset = newValue ? scrollOffset.rounded() : nil
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .updating($isGestureActive) { _, out, _ in
                    out = true
                }
                .onChanged { value in
                    /// only allow custom pull action when scroll is not active
                    guard initialScrollOffset == 0 else { return }
                    let translationY = value.translation.height
                    let progress = min(max(translationY / dragDistance, 0), 1)
                    effectProgress = progress

                    /// setup activePositon index
                    guard translationY >= dragDistance else {
                        activePositon = nil
                        return
                    }
                    let translationX = value.translation.width
                    let indexProgress = translationX / dragDistance
                    let index: Int = -indexProgress > 0.5 ? -1 : (indexProgress > 0.5 ? 1 : 0)
                    let landingAction = ActionPosition.allCases.first { $0.rawValue == index }

                    if activePositon != landingAction {
                        hapticTrigger.toggle()
                    }
                    activePositon = landingAction
                }
                .onEnded { _ in
                    guard effectProgress != 0 else { return }
                    if let activePositon {
                        withAnimation(
                            .easeInOut(duration: 0.25),
                            completionCriteria: .logicallyComplete
                        ) {
                            scaleEffect = true
                        } completion: {
                            scaleEffect = false
                            effectProgress = 0
                            self.activePositon = nil
                        }

                        /// trigger active position action
                        switch activePositon {
                        case .leading: leadingAction.action()
                        case .center: centerAction.action()
                        case .trailing: trailingAction.action()
                        }
                    } else {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            effectProgress = 0
                        }
                    }
                },
            isEnabled: !scaleEffect
        )
        .background(alignment: .top) {
            actionsView()
                .padding(.top, actionTopPadding)
                .ignoresSafeArea()
        }
        /// provide haptics
        .sensoryFeedback(.impact, trigger: hapticTrigger)
    }

    /// use topPadding to dynamiccally apply vertical padding to sync with scroll position
    private func actionsView() -> some View {
        HStack(spacing: 0) {
            let delayedProgress = (effectProgress - 0.7) / 0.3
            actionButton(.leading)
                .offset(x: 30 * (1 - delayedProgress))
                .opacity(delayedProgress)

            actionButton(.center)
                .blur(radius: 10 * (1 - effectProgress))
                .opacity(effectProgress)

            actionButton(.trailing)
                .offset(x: -30 * (1 - delayedProgress))
                .opacity(delayedProgress)
        }
        .padding(.horizontal, 20)
    }

    private func actionButton(_ position: ActionPosition) -> some View {
        var action: PullEffectAction = centerAction
        switch position {
        case .center:
            action = centerAction
        case .leading:
            action = leadingAction
        case .trailing:
            action = trailingAction
        }

        return Image(systemName: action.symbol)
            .font(.title2)
            .fontWeight(.semibold)
            .opacity(scaleEffect ? 0 : 1)
            .animation(.linear(duration: 0.05), value: scaleEffect)
            .frame(width: 60, height: 60)
            .background {
                if activePositon == position {
                    ZStack {
                        Rectangle()
                            .fill(.background)

                        Rectangle()
                            .fill(.gray.opacity(0.2))
                    }
                    .clipShape(.rect(cornerRadius: scaleEffect ? 0 : 30))
                    .compositingGroup()
                    .matchedGeometryEffect(id: "INDICATOR", in: animation)
                    .scaleEffect(scaleEffect ? 20 : 1, anchor: .bottom)
                }
            }
            .frame(maxWidth: .infinity)
            .compositingGroup()
            .animation(.easeInOut(duration: 0.25), value: activePositon)
    }

    private enum ActionPosition: Int, CaseIterable {
        case leading = -1
        case center = 0
        case trailing = 1
    }
}

struct PullEffectAction {
    var symbol: String
    var action: () -> Void
}

#Preview {
    PullEffectScrollViewDemo()
}
