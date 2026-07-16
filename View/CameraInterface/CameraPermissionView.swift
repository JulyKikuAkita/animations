//
//  CameraPermissionView.swift
//  animation
//
//  Created on 7/15/26.
//
//  Learning point
//  ──────────────
//  A system-style camera permission prompt with a looping mockup above it:
//  a phone frame pans left/right through a panorama, dips down to reveal a
//  shutter bar, then resets — while a small chevron bounces underneath the
//  camera icon to hint "scroll/expand". Two different keyframe APIs are used
//  for two different jobs, and each `Keyframe` *type* inside them is picked
//  for what it does to the interpolation, not interchangeably.
//
//  Mechanics
//  ─────────
//    1. The chevron uses `.keyframeAnimator(initialValue:)` — the *modifier*
//       form — because it drives exactly one plain `Double` (a y-offset).
//    2. The phone mockup uses `KeyframeAnimator(initialValue:)` — the *view*
//       form — driving `AnimatedFrame`, an `@Animatable` struct bundling
//       `scale` + `camOpacity` + `progress`. Bundling them into one struct is
//       what lets all three stay on a single shared timeline instead of
//       three separate `.animation()` calls that could drift out of phase.
//
//  Keyframe types — why each one, not just which
//  ───────────────────────────────────────────────
//    • `MoveKeyframe` — jumps to a value with NO interpolation or duration.
//      Used as the very first keyframe in the phone's `repeating: true`
//      track so each loop iteration snaps to the start instantly instead of
//      easing in from wherever the previous cycle's `SpringKeyframe` settled;
//      a `MoveKeyframe` never blends with what came before it.
//    • `LinearKeyframe` — constant-rate change to the target. Used for the
//      "Initial Delay" / "Little Delay" / "End delay" steps by repeating the
//      *same* `AnimatedFrame` value as the previous keyframe — there is no
//      dedicated "wait" keyframe, so a zero-change segment is how you spend
//      duration without moving anything.
//    • `CubicKeyframe` — eased in/out via a spline through neighboring
//      keyframes. Used for the real shape changes: scaling down + fading the
//      shutter bar in, and the final reset back to identity — motion that
//      should decelerate smoothly into its endpoint rather than stop on a
//      hard edge. The chevron's bounce uses it for the same reason (ease up,
//      ease back down), with a same-value `CubicKeyframe` appended as its own
//      "wait time" before the loop repeats.
//    • `SpringKeyframe` — interpolates via spring physics instead of a fixed
//      curve. Used for all three pan positions (left/right/center) because a
//      camera pan reads as physical, weighted motion; giving all three the
//      same `.smooth(duration: 1, extraBounce: 0)` spring keeps the settle
//      feel identical at every stop instead of compounding across them.
//
//  Key APIs
//  ────────
//  • `.keyframeAnimator(initialValue:repeating:)` — single-value modifier.
//  • `KeyframeAnimator(initialValue:repeating:)` + `@Animatable` — multi-value
//    view form; the struct's properties move together on one clock.
//  • `MoveKeyframe` / `LinearKeyframe` / `CubicKeyframe` / `SpringKeyframe` —
//    see above; mixing them inside one `KeyframeTrack` is expected, each
//    segment picks the curve that matches what it's supposed to feel like.
//
//  How to apply
//  ────────────
//  Reach for the `KeyframeAnimator` *view* as soon as more than one property
//  must animate in lockstep; reach for the `.keyframeAnimator` *modifier*
//  when it's just one. Build pauses by repeating the previous target value
//  rather than looking for a dedicated wait keyframe. Open a repeating track
//  with `MoveKeyframe` so the loop boundary is a hard cut, not an eased blend.
//
//  See also
//  ────────
//  • View/LandingPages/PermissionOnboardingIOS26.swift — sibling pattern:
//    one `@Animatable Frame` + `KeyframeAnimator`, spring for the "pop" and
//    linear for the dwell phases.

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
            /// overlay, not ZStack: the VStack sizes to this Rectangle's bounds
            /// instead of a separately-sized sibling container.
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
                /// overlay: pins the badge to the icon's frame without adding
                /// to its layout size — vs. ZStack(alignment: .topLeading),
                /// which would need that 80x80 frame duplicated on a sibling.
                .overlay(alignment: .topLeading) {
                    Image(systemName: "chevron.down")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 15, height: 15)
                        /// Single Double (offset) → the `.keyframeAnimator`
                        /// *modifier* is enough; no other property to sync.
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

            /// Drives AnimatedFrame (scale + camOpacity + progress together) →
            /// needs the `KeyframeAnimator` *view* form so all three move on
            /// one shared timeline instead of drifting across separate
            /// `.animation()` calls.
            KeyframeAnimator(initialValue: AnimatedFrame(), repeating: true) { frame in
                Rectangle()
                    .fill(.fill)
                    /// pano & shutter ui — overlay so the clipShape() below
                    /// clips this content together with the base Rectangle;
                    /// .background would put it behind instead.
                    .overlay {
                        ZStack(alignment: .bottom) {
                            Rectangle()
                                .fill(.black)
                                /// overlay: opaque black backdrop sized to this
                                /// Rectangle, so panning the 3x-wide panorama
                                /// never reveals anything behind it.
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
                    /// Dynamic island — overlay(alignment: .top) layers above
                    /// the finished phone-frame stack without resizing it;
                    /// vs. ZStack(alignment: .top), which would need that
                    /// alignment repeated on every sibling.
                    .overlay(alignment: .top) {
                        Capsule()
                            .fill(.black)
                            .stroke(.fill, lineWidth: 1)
                            .frame(width: 120 * ratio, height: 36 * ratio)
                            /// Camera dot — overlay(alignment: .center) so the
                            /// .offset(x:) below can nudge it independent of
                            /// the capsule's own frame.
                            .overlay(alignment: .center) {
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
