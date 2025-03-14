//
//  CustomSwipeActions.swift
//  animation
//
import SwiftUI

/// Swipe Action Builder
/// Accepts a set of SwipeActionModel without any return or commas and returns it in an array format
@resultBuilder
struct SwipeActionBuilder {
    static func buildBlock(_ components: SwipeActionModel...) -> [SwipeActionModel] {
        components
    }
}

/// Custom Properties
struct SwipeActionConfig {
    var leadingPadding: CGFloat = 0
    var trailingPadding: CGFloat = 10
    var spacing: CGFloat = 10
    var occupiesFullWidth: Bool = false
}

@MainActor
@Observable
final class SwipeActionSharedData {
    static let shared = SwipeActionSharedData()
    var actionSwipeAction: String?
}

extension View {
    @ViewBuilder
    func swipeActions(config: SwipeActionConfig = .init(), @SwipeActionBuilder actions: () -> [SwipeActionModel]) -> some View {
        modifier(CustomSwipeActionModifier(config: config, actions: actions()))
    }
}

private struct CustomSwipeActionModifier: ViewModifier {
    var config: SwipeActionConfig
    var actions: [SwipeActionModel]
    /// View Properties
    @State private var resetPositionTrigger: Bool = false
    @State private var offsetX: CGFloat = 0
    @State private var lastStoreOffsetX: CGFloat = 0
    @State private var bounceOffset: CGFloat = 0
    @State private var progress: CGFloat = 0
    /// Scroll Properties
    @State private var currentScrollOffset: CGFloat = 0
    @State private var storedScrollOffset: CGFloat?
    var sharedData = SwipeActionSharedData.shared
    @State private var currentID: String = UUID().uuidString

    func body(content: Content) -> some View {
        content
            .overlay {
                Rectangle()
                    .foregroundStyle(.clear)
                    .containerRelativeFrame(config.occupiesFullWidth ? .horizontal : .init())
                    .overlay(alignment: .trailing) {
                        ActionsView()
                    }
            }
            .compositingGroup()
            .offset(x: offsetX)
            .offset(x: bounceOffset)
            .mask {
                Rectangle()
                    .containerRelativeFrame(config.occupiesFullWidth ? .horizontal : .init())
            }
            .gesture(
                HorizontalPanGesture(onBegan: {
                    gestureDidBegan()
                }, onChange: { value in
                    gestureDidChange(translation: value.translation)
                }, onEnd: { value in
                    gestureDidEnded(translation: value.translation, velocity: value.velocity)
                })
            )
            .onChange(of: resetPositionTrigger) { _, _ in
                reset()
            }
            .onGeometryChange(for: CGFloat.self) {
                $0.frame(in: .scrollView).minY
            } action: { newValue in
                if let storedScrollOffset, storedScrollOffset != newValue {
                    reset()
                }
            }
            .onChange(of: sharedData.actionSwipeAction) { _, newValue in
                if newValue != currentID, offsetX != 0 {
                    reset()
                }
            }
    }

    @ViewBuilder
    func ActionsView() -> some View {
        ZStack {
            ForEach(actions.indices, id: \.self) { index in
                let action = actions[index]

                GeometryReader { proxy in
                    let size = proxy.size
                    let spacing = config.spacing * CGFloat(index)
                    let offset = CGFloat(index) * size.width

                    Button(action: { action.action(&resetPositionTrigger) }) {
                        Image(systemName: action.symbolImage)
                            .font(action.font)
                            .foregroundStyle(action.tint)
                            .frame(width: size.width, height: size.height)
                            .background(action.background, in: action.shape)
                    }
                    .offset(x: offset * progress)
                }
                .frame(width: action.size.width, height: action.size.height)
            }
        }
        .visualEffect { content, proxy in
            content
                .offset(x: proxy.size.width)
        }
        .offset(x: config.leadingPadding)
    }

    private func gestureDidBegan() {
        storedScrollOffset = lastStoreOffsetX
        sharedData.actionSwipeAction = currentID
    }

    private func gestureDidChange(translation: CGSize) {
        offsetX = min(max(translation.width + lastStoreOffsetX, -maxOffsetWidth), 0)
        progress = -offsetX / maxOffsetWidth

        bounceOffset = min(translation.width - (offsetX - lastStoreOffsetX), 0) / 10
    }

    private func gestureDidEnded(translation _: CGSize, velocity: CGSize) {
        let endTarget = velocity.width + offsetX

        withAnimation(.snappy(duration: 0.3, extraBounce: 0)) {
            if -endTarget > (maxOffsetWidth * 0.6) {
                offsetX = -maxOffsetWidth
                bounceOffset = 0
                progress = 1
            } else {
                /// Reset to initial position
                reset()
            }
        }
        lastStoreOffsetX = offsetX
    }

    private func reset() {
        withAnimation(.snappy(duration: 0.3, extraBounce: 0)) {
            offsetX = 0
            lastStoreOffsetX = 0
            bounceOffset = 0
            progress = 0
        }
        storedScrollOffset = nil
    }

    var maxOffsetWidth: CGFloat {
        let totalActionSize: CGFloat = actions.reduce(.zero) { partialResult, action in
            partialResult + action.size.width
        }

        let spacing = config.spacing * CGFloat(actions.count - 1)

        return totalActionSize + spacing + config.leadingPadding + config.trailingPadding
    }
}
