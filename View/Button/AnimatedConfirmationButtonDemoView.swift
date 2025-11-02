//
//  AnimatedConfirmationButtonDemoView.swift
//  animation
//
//  Created on 11/1/25.

import SwiftUI

struct AnimatedConfirmationButtonDemoView: View {
    var body: some View {
        VStack {
            AnimatedConfirmationButton {
                VStack(alignment: .leading, spacing: 15) {
                    Image(systemName: "exclamationmark.circle")
                        .font(.largeTitle)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    DummySection(title: "Are you Sure?")
                }
                .padding(.bottom, 10)
            } label: {
//                Text("Test")
//                    .foregroundStyle(Color.white)
//                    .fontWeight(.medium)
//                    .frame(maxWidth: .infinity)
//                    .padding(.vertical, 11)
//                    .background(.red.gradient)

                Image(systemName: "trash.fill")
                    .foregroundStyle(Color.white)
                    .frame(width: 45, height: 45)
                    .background(.red.gradient)
            } action: { _ in
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding()
    }
}

struct AnimatedButtonCorderRadius {
    var source: CGFloat = 30
    var destination: CGFloat = 45
}

private struct AnimatedButtonProperties {
    var sourceLocation: CGRect = .zero
    var sourceView: UIImage?
    var hideSource: Bool = false
    var animate: Bool = false
    var showConfirmationView: Bool = false
}

struct AnimatedConfirmationButton<Content: View, Label: View>: View {
    var cornerRadius: AnimatedButtonCorderRadius = .init()
    @ViewBuilder var content: Content
    @ViewBuilder var label: Label
    var action: (_ isCancelled: Bool) -> Void
    @State fileprivate var properties: AnimatedButtonProperties = .init()
    @Environment(\.displayScale) private var displayScale: CGFloat
    var body: some View {
        Button {
            let renderer = ImageRenderer(content:
                label
                    .frame(width: properties.sourceLocation.width,
                           height: properties.sourceLocation.height)
                    .clipShape(.rect(cornerRadius: cornerRadius.source))
                    .contentShape(.rect(cornerRadius: cornerRadius.source))
            )
            renderer.scale = displayScale
            properties.sourceView = renderer.uiImage

            /// show the full cover screen without default animation
            noAnimation {
                properties.showConfirmationView = true
            }
        } label: {
            label
                .clipShape(.rect(cornerRadius: cornerRadius.source))
                .contentShape(.rect(cornerRadius: cornerRadius.source))
                /// hiding source view
                .opacity(properties.showConfirmationView ? 0 : 1)
        }
        .onGeometryChange(for: CGRect.self, of: {
            $0.frame(in: .global)
        }, action: { newValue in
            properties.sourceLocation = newValue
        })
        .buttonStyle(.plain)
        /// use full screen cover to make sure animation works in any place of the view
        .fullScreenCover(isPresented: $properties.showConfirmationView) {
            ConfirmationButtonView(cornerRadius: cornerRadius, properties: $properties) {
                content
            } action: { isUserCancelled in
                action(isUserCancelled)
            }
            .ignoresSafeArea()
            .presentationBackground(Color.clear)
            .persistentSystemOverlays(.hidden)
        }
    }
}

private struct ConfirmationButtonView<Content: View>: View {
    var cornerRadius: AnimatedButtonCorderRadius
    @Binding fileprivate var properties: AnimatedButtonProperties
    @ViewBuilder var content: Content
    var action: (_ isUserCancelled: Bool) -> Void

    /// create a zoom transition animation effect
    var body: some View {
        let animate = properties.animate
        let hideSource = properties.hideSource
        let sourceLocation = properties.sourceLocation

        ZStack(alignment: .bottom) {
            Rectangle()
                .fill(.black.opacity(animate ? 0.4 : 0))

            VStack(spacing: 10) {
                content
                actionButtons()
            }
            .allowsHitTesting(animate)
            .padding(20)
            .compositingGroup()
            .geometryGroup()
            .background(.background, in: .rect)
            .blur(radius: animate ? 0 : 10)
            .opacity(animate ? 1 : 0) // without fading effect, replace with  .opacity(properties.showConfirmationView ? 1 : 0)
            .background { // without fading effect, replace with overlay
                GeometryReader {
                    let size = $0.size
                    if let sourceView = properties.sourceView {
                        Image(uiImage: sourceView)
                            .resizable()
                            .frame(
                                width: animate ? size.width : sourceLocation.width,
                                height: animate ? size.height : sourceLocation.height
                            )
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .blur(radius: hideSource ? 10 : 0)
                            .opacity(hideSource ? 0 : 1)
                    }
                }
            }
            .mask {
                /// use mask, instead of frame to change view size to achieve clean effect without text clipping and other unwanted effect
                clipShape
                    .frame(width: animate ? nil : sourceLocation.width,
                           height: animate ? nil : sourceLocation.height)
            }
            .padding(.horizontal, 10)
            .visualEffect { content, proxy in /// animate transition from source to destination
                content
                    .offset(
                        x: animate ? 0 : sourceLocation.midX - (proxy.size.width / 2),
                        y: animate ? 0 : sourceLocation.midY - (proxy.size.height / 2),
                    )
            }
            /// coordinate begins with  top left
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: animate ? .bottom : .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(animation) {
                properties.animate = true
            }

            Task {
                withAnimation(sourceAnimation) {
                    properties.hideSource = true
                }
            }
        }
    }

    private func actionButtons() -> some View {
        HStack(spacing: 6) {
            Button {
                dismiss(false)
            } label: {
                Text("Cancel")
                    .foregroundStyle(Color.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(.gray.opacity(0.3))
                    .clipShape(.capsule)
            }

            Button {
                dismiss(true)
            } label: {
                Text("Delete")
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(.red.gradient)
                    .clipShape(.capsule)
            }
        }
        .fontWeight(.medium)
    }

    var clipShape: AnyShape {
        let radius = properties.animate ? cornerRadius.destination : cornerRadius.source
        return .init(.rect(cornerRadius: radius))
    }

    var animation: Animation {
        .interpolatingSpring(duration: 0.3)
    }

    var sourceAnimation: Animation {
        .interpolatingSpring(duration: 0.15)
    }

    func dismiss(_ status: Bool) {
        withAnimation(animation, completionCriteria: .removed) {
            properties.animate = false
        } completion: {
            noAnimation {
                properties.sourceView = nil
                properties.showConfirmationView = false
            }
            action(status)
        }
        Task {
            withAnimation(sourceAnimation.delay(0.08)) {
                properties.hideSource = false
            }
        }
    }
}

#Preview {
    AnimatedConfirmationButtonDemoView()
}
