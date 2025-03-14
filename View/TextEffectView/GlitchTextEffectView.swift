//
//  GlitchTextEffectView.swift
//  animation
//  Using KeyframeAnimator API
import SwiftUI

struct GlitchTextEffectDemoView: View {
    /// View properties
    @State private var trigger: (Bool, Bool, Bool) = (false, false, false)
    var body: some View {
        VStack {
            GlitchText("Made in Abyss", trigger: trigger.0)
                .font(.system(size: 48, weight: .semibold))

            GlitchText("Nanachi", trigger: trigger.1)
                .font(.system(size: 32, design: .rounded))

            GlitchText("Season 1", trigger: trigger.2)
                .font(.system(size: 20))

            Button(action: {
                Task {
                    trigger.0.toggle()
                    try? await Task.sleep(for: .seconds(0.6))

                    trigger.1.toggle()
                    try? await Task.sleep(for: .seconds(0.6))

                    trigger.2.toggle()
                }
            }, label: {
                Text("Trigger")
                    .padding(.horizontal, 15)
            })
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .tint(.black)
        }
        .padding()
    }

    @ViewBuilder
    func GlitchText(_ text: String, trigger: Bool) -> some View {
        ZStack {
            GlitchTextEffectView(text: text, trigger: trigger, shadow: .red) {
                LinearKeyframe(
                    GlitchFrame(top: -5, center: 0, bottom: 0, shadowOpacity: 0.2),
                    duration: 0.1
                )

                LinearKeyframe(
                    GlitchFrame(top: -5, center: -5, bottom: -5, shadowOpacity: 0.6),
                    duration: 0.1
                )

                LinearKeyframe(
                    GlitchFrame(top: -5, center: -5, bottom: 5, shadowOpacity: 0.8),
                    duration: 0.1
                )

                LinearKeyframe(
                    GlitchFrame(top: 5, center: 5, bottom: 5, shadowOpacity: 0.4),
                    duration: 0.1
                )

                LinearKeyframe(
                    GlitchFrame(top: 5, center: 0, bottom: 5, shadowOpacity: 0.2),
                    duration: 0.1
                )

                LinearKeyframe(
                    GlitchFrame(),
                    duration: 0.1
                )
            }

            GlitchTextEffectView(text: text, trigger: trigger, shadow: .green) {
                LinearKeyframe(
                    GlitchFrame(top: 0, center: 5, bottom: 0, shadowOpacity: 0.2),
                    duration: 0.1
                )

                LinearKeyframe(
                    GlitchFrame(top: 5, center: 5, bottom: 5, shadowOpacity: 0.3),
                    duration: 0.1
                )

                LinearKeyframe(
                    GlitchFrame(top: 5, center: 5, bottom: -5, shadowOpacity: 0.5),
                    duration: 0.1
                )

                LinearKeyframe(
                    GlitchFrame(top: 0, center: 5, bottom: -5, shadowOpacity: 0.6),
                    duration: 0.1
                )

                LinearKeyframe(
                    GlitchFrame(top: 0, center: -5, bottom: 0, shadowOpacity: 0.3),
                    duration: 0.1
                )

                LinearKeyframe(
                    GlitchFrame(),
                    duration: 0.1
                )
            }
        }
    }
}

/// KeyFrame must conform to the Animatable protocol
/// Below demo how to use several values in the Animatable protocol (AnimatablePair)
struct GlitchFrame: Animatable {
    var animatableData: AnimatablePair<CGFloat, AnimatablePair<CGFloat, AnimatablePair<CGFloat, CGFloat>>> {
        get {
            .init(top, .init(center, .init(bottom, shadowOpacity)))
        }
        set {
            top = newValue.first
            center = newValue.second.first
            bottom = newValue.second.second.first
            shadowOpacity = newValue.second.second.second
        }
    }

    /// X-offset's
    var top: CGFloat = 0
    var center: CGFloat = 0
    var bottom: CGFloat = 0
    var shadowOpacity: CGFloat = 0
}

/// Result Builder
@resultBuilder
struct GlitchFrameBuilder {
    static func buildBlock(_ components: LinearKeyframe<GlitchFrame>...) -> [LinearKeyframe<GlitchFrame>] {
        components
    }
}

struct GlitchTextEffectView: View {
    var text: String
    /// Config
    var trigger: Bool
    var shadow: Color
    var radius: CGFloat
    var frames: [LinearKeyframe<GlitchFrame>]

    init(text: String, trigger: Bool, shadow: Color = .red, radius: CGFloat = 1, @GlitchFrameBuilder frames: @escaping () -> [LinearKeyframe<GlitchFrame>]) {
        self.text = text
        self.trigger = trigger
        self.shadow = shadow
        self.radius = radius
        self.frames = frames()
    }

    var body: some View {
        KeyframeAnimator(initialValue: GlitchFrame(), trigger: trigger) { value in
            ZStack {
                TextView(.top, offset: value.top, opacity: value.shadowOpacity)
                TextView(.center, offset: value.center, opacity: value.shadowOpacity)
                TextView(.bottom, offset: value.bottom, opacity: value.shadowOpacity)
            }
            .compositingGroup() // not require
        } keyframes: { _ in
            for frame in frames {
                frame
            }
        }
    }

    @ViewBuilder
    func TextView(_ alignment: Alignment, offset: CGFloat, opacity: CGFloat) -> some View {
        Text(text)
            .mask {
                if alignment == .top {
                    VStack(spacing: 0) {
                        // trick to create a view with 1/3 height
                        Rectangle()
                        ExtendedSpacer()
                        ExtendedSpacer()
                    }
                } else if alignment == .center {
                    VStack(spacing: 0) {
                        ExtendedSpacer()
                        Rectangle()
                        ExtendedSpacer()
                    }
                } else {
                    VStack(spacing: 0) {
                        ExtendedSpacer()
                        ExtendedSpacer()
                        Rectangle()
                    }
                }
            }
            .shadow(color: shadow.opacity(opacity), radius: radius, x: offset, y: offset / 2) // use your choice of offset for y, input a new value if preferred
            .offset(x: offset)
    }

    @ViewBuilder
    func ExtendedSpacer() -> some View {
        Spacer(minLength: /*@START_MENU_TOKEN@*/0/*@END_MENU_TOKEN@*/)
            .frame(maxHeight: .infinity)
    }
}

#Preview {
    GlitchTextEffectDemoView()
}
