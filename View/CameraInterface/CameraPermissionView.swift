//
//  CameraPermissionView.swift
//  animation
//
//  Created on 7/15/26.

import SwiftUI

@available(iOS 26.0, *)
struct CameraPermissionDemo: View {
    var body: some View {
        CameraPermissionView(
            title: "Camera Permission",
            description: dummyTitle,
            primaryActionTitle: "Enable Camera Access",
            secondaryActionTitle: "Ask Later",
            hidesShutterUI: false
        ) {} secondaryAction: {} panorama: {
            /// panoramic effect, use image width 1170 (390 * 3)
            /// e.g.,  .IMG_0207

            Image(.nanachiPaint)
                .resizable()
        }
    }
}

@available(iOS 26.0, *)
struct CameraPermissionView: View {
    var tint: Color = .blue
    var title: String
    var description: String
    var primaryActionTitle: String
    var secondaryActionTitle: String
    var hidesShutterUI: Bool = false
    var primaryAction: () -> Void
    var secondaryAction: () -> Void
    var panorama: () -> Image
    var body: some View {
        Rectangle()
            .fill(.black)
            .ignoresSafeArea()
            .overlay {
                VStack(spacing: 0) {
                    Spacer(minLength: 0)

                    permissionAnimation()
                        .padding(.top, 15)
                        .padding(.bottom, 25)

                    permissionContent()
                }
            }
            .fontDesign(.rounded)
            .environment(\.colorScheme, .dark)
    }

    @ContentBuilder
    private func permissionContent() -> some View {
        VStack(spacing: 10) {
            /// keyframe animation on "chevron.down"
            Image(systemName: "camera")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .fontWeight(.ultraLight)
                .frame(width: 80, height: 80)
                .overlay(alignment: .topLeading) {
                    Image(systemName: "chevron.down")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 15, height: 15)
                        .keyframeAnimator(initialValue: -5.0, repeating: true) { content, offset in
                            content
                                .offset(y: offset)
                        } keyframes: { _ in
                            CubicKeyframe(0, duration: 1)
                            CubicKeyframe(-5, duration: 1)
                            /// wait time
                            CubicKeyframe(-5, duration: 0.5)
                        }
                        .padding(.bottom, 10)
                }

            Text(title)
                .font(.title.bold())
                .lineLimit(1)

            Text(description)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            Button(action: primaryAction) {
                Text(primaryActionTitle)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .tint(tint)
            .buttonStyle(.glassProminent)
            .buttonBorderShape(.capsule)
            .padding(.top, 15)

            Button(secondaryActionTitle, action: secondaryAction)
                .tint(.secondary)
                .padding(.top, 5)
        }
        .frame(maxWidth: 330)
        .padding(.bottom, 15)
    }

    @ContentBuilder
    private func permissionAnimation() -> some View {
        let iPhoneRatio: CGFloat = 390 / 870
        let iPhoneCornerRadius: CGFloat = 47
        GeometryReader {
            let size = $0.size
            let ratio = min(size.width / 390, size.height / 870)

            KeyframeAnimator(initialValue: AnimatedFrame(), repeating: true) { frame in
                Rectangle()
                    .fill(.fill)
                    /// pano & shutter ui
                    .overlay {
                        ZStack(alignment: .bottom) {
                            Rectangle()
                                .fill(.black)
                                .overlay {
                                    panorama()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: size.width * 3, height: size.height)
                                        .offset(x: -frame.progress * size.width)
                                }

                            if hidesShutterUI {
                                HStack(spacing: 0) {
                                    Circle()
                                        .fill(.white.secondary)
                                        .frame(width: size.height * 0.05)

                                    Circle()
                                        .fill(.white)
                                        .frame(width: size.height * 0.2, height: size.height * 0.1)

                                    Circle()
                                        .fill(.white.secondary)
                                        .frame(width: size.height * 0.05)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: size.height * 0.17)
                                .background(.black.opacity(0.5))
                            }
                        }
                        .clipped()
                        .offset(y: size.height - (size.height * frame.camOpacity))
                    }
                    /// Dynamic island
                    .overlay(alignment: .top) {
                        Capsule()
                            .fill(.black)
                            .stroke(.fill, lineWidth: 1)
                            .frame(width: 120 * ratio, height: 36 * ratio)
                            .overlay(alignment: .center) {
                                /// Camera dot
                                Circle()
                                    .fill(.green)
                                    .frame(width: 10 * ratio, height: 10 * ratio)
                                    .offset(x: 12 * ratio)
                                    .opacity(frame.camOpacity)
                            }
                            .padding(.top, 11 * ratio)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: iPhoneCornerRadius * ratio))
                    .background {
                        RoundedRectangle(cornerRadius: iPhoneCornerRadius * ratio)
                            .stroke(.fill, lineWidth: 2)
                    }
                    .compositingGroup()
                    .scaleEffect(frame.scale, anchor: .center)
                    /// Set Z: value to 0 to remove tilt effect
                    .rotation3DEffect(
                        .degrees(frame.progress * 15),
                        axis: (x: 0, y: abs(frame.progress), z: abs(frame.progress / 4)),
                        anchor: .center
                    )
                    .offset(x: frame.progress * 80)
            } keyframes: { _ in
                MoveKeyframe(AnimatedFrame())
                /// Initial Delay
                LinearKeyframe(AnimatedFrame(), duration: 0.5)

                CubicKeyframe(AnimatedFrame(scale: 0.95, camOpacity: 1), duration: 0.5)
                CubicKeyframe(AnimatedFrame(scale: 0.95, camOpacity: 1), duration: 0.5)

                /// Little Delay
                LinearKeyframe(AnimatedFrame(scale: 0.95, camOpacity: 1), duration: 0.5)

                /// Left
                SpringKeyframe(
                    AnimatedFrame(scale: 0.95, camOpacity: 1, progress: -1),
                    duration: 1.5,
                    spring: .smooth(duration: 1, extraBounce: 0)
                )

                /// Right
                SpringKeyframe(
                    AnimatedFrame(scale: 0.95, camOpacity: 1, progress: 1),
                    duration: 1.5,
                    spring: .smooth(duration: 1, extraBounce: 0)
                )

                /// Center
                SpringKeyframe(
                    AnimatedFrame(scale: 0.95, camOpacity: 1, progress: 0),
                    duration: 1.5,
                    spring: .smooth(duration: 1, extraBounce: 0)
                )

                /// Reset
                CubicKeyframe(AnimatedFrame(), duration: 0.35)

                /// End delay
                LinearKeyframe(AnimatedFrame(), duration: 0.5)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(iPhoneRatio, contentMode: .fit)
    }

    @Animatable
    struct AnimatedFrame {
        var scale: CGFloat = 1
        var camOpacity: CGFloat = 0
        var progress: CGFloat = 0
    }
}

@available(iOS 26.0, *)
#Preview {
    CameraPermissionDemo()
}
