//
//  PlayerContainer.swift
//  animation
//
//  Created on 9/9/26.

import SwiftUI

struct PlayerContainerConfig {
    var minimizedPlayerRect: CGRect = .zero
    var attachExpandedPlayer: Bool = false
    var expandPlayer: Bool = false
    var dragOffset: CGFloat = .zero
    var animation: Animation = .interpolatingSpring(duration: 0.3, bounce: 0, initialVelocity: 0)
}

@available(iOS 27.0, *)
struct PlayerContainer: View {
    @Binding var config: PlayerContainerConfig
    @Namespace private var namespace
    var body: some View {
        if config.attachExpandedPlayer {
            let expandedPlayer = config.expandPlayer
            let minimizedRect = config.minimizedPlayerRect
            let minimumRadius = minimizedRect.height / 2
            let shape = ConcentricRectangle(
                corners: .concentric(minimum: .fixed(minimumRadius)),
                isUniform: true
            )
            GeometryReader {
                let safeArea = $0.safeAreaInsets
                let size = CGSize(
                    width: $0.size.width + safeArea.leading + safeArea.trailing,
                    height: $0.size.height + safeArea.top + safeArea.bottom
                )

                ZStack {
                    if expandedPlayer {
                        ExtendedPlayer(
                            size: size,
                            safeArea: safeArea,
                            namespace: namespace,
                            config: $config
                        ) {
                            toggleExpandedPlayer(status: false)
                        }
                        .geometryGroup()
                        .transition(.opacity)
                    }
                }
                .frame(width: expandedPlayer ? size.width : minimizedRect.width,
                       height: expandedPlayer ? size.height : minimizedRect.height)
                .overlay(alignment: .top) {
                    if !expandedPlayer {
                        MiniPlayer(namespace: namespace)
                            .frame(height: minimizedRect.height)
                            .geometryGroup()
                            .transition(.opacity)
                    }
                }
                .contentShape(shape)
                .clipShape(shape)
                .glassEffect(.regular, in: shape)
                .visualEffect { [config] content, proxy in
                    let globalRect = proxy.frame(in: .global)
                    return content
                        .offset(y: config.dragOffset)
                        .offset(x: expandedPlayer ? 0 : (minimizedRect.minX - globalRect.minX),
                                y: expandedPlayer ? 0 : (minimizedRect.minY - globalRect.minY))
                }
                .gesture(
                    PanGesture { value in
                        config.dragOffset = max(0, value.translation.height)
                    } onEnd: { value in
                        let velocity = max(value.velocity.height / 5, 0)
                        let end = config.dragOffset + velocity

                        if end > (size.height / 2) {
                            toggleExpandedPlayer(status: false)
                        } else {
                            withAnimation(config.animation) {
                                config.dragOffset = 0
                            }
                        }
                    }
                )
                .ignoresSafeArea()
            }
        } else {
            MiniPlayer(namespace: namespace)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(.rect)
                .onTapGesture {
                    toggleExpandedPlayer(status: true)
                }
                /// Extracting mini player rect
                .onGeometryChange(for: CGRect.self) {
                    $0.frame(in: .global)
                } action: { newValue in
                    guard !config.attachExpandedPlayer else { return }
                    config.minimizedPlayerRect = newValue
                }
        }
    }

    private func toggleExpandedPlayer(status: Bool) {
        if status {
            /// intentional delay for the glass effect to complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
                config.attachExpandedPlayer = true
                withAnimation(config.animation) {
                    config.expandPlayer = true
                }
            }
        } else {
            withAnimation(config.animation, completionCriteria: .removed) {
                config.dragOffset = 0
                config.expandPlayer = false
            } completion: {
                config.attachExpandedPlayer = false
            }
        }
    }
}
