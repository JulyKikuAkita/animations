//
//  PermissionOnboardingIOS26.swift
//  animation
//
//  Created on 2/25/26.
// Animation Using SwiftUI | KeyFrames
import SwiftUI

struct PermissionOnboarding: View {
    var config: Config
    /// View Properties
    @State private var showPermissionAnimation: Bool = false
    @Environment(\.colorScheme) private var colorScheme
    var body: some View {
        ZStack(alignment: .bottom) {
            iPhoneView()

            VStack(spacing: 15) {
                Text(config.title)
                    .font(.title.bold())
                    .multilineTextAlignment(.center)

                Text(config.description)
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.bottom, 10)

                Button {} label: {
                    Text(config.primaryTitle)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(config.buttonTint)
                .frame(height: 45)
                .frame(maxWidth: 300)

                if let secondaryTitle = config.secondaryTitle,
                   let secondaryAction = config.secondaryAction
                {
                    Button {
                        secondaryAction()
                    } label: {
                        Text(secondaryTitle)
                            .font(.callout)
                            .fontWeight(.semibold)
                            .foregroundStyle(.gray)
                    }
                }
            }
            .frame(height: 220)
            .padding(15)
            .frame(maxWidth: .infinity)
            /// Variable blur background
            .background {
                Rectangle()
                    .fill(background)
                    .blur(radius: 25)
                    .padding(.all, -60)
                    .ignoresSafeArea()
            }
        }
        .padding(.top, 20)
        .task {
            guard !showPermissionAnimation else { return }
            try? await Task.sleep(for: .seconds(config.initialDelay))
            showPermissionAnimation = true
        }
    }

    func iPhoneView() -> some View {
        Rectangle()
            .foregroundStyle(.clear)
            .overlay(alignment: .top) {
                let cornerRadius: CGFloat = 55
                let fill = Color.primary.opacity(0.15)
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(fill)
                        .overlay(alignment: .top) {
                            /// Status bar
                            HStack(spacing: 12) {
                                Text("9:41")

                                Image(systemName: "wifi")

                                Image(systemName: "battery.50percent")
                            }
                            .font(.system(size: 18))
                            .fontWeight(.medium)
                            .frame(height: 37)
                            .padding(.horizontal, 30)
                            .offset(y: 20)
                        }
                        .overlay(alignment: .top) {
                            /// Dynamic Island
                            Capsule()
                                .fill(.black)
                                .frame(width: 120, height: 37)
                                .offset(y: 20)
                        }

                    ZStack {
                        RoundedRectangle(cornerRadius: cornerRadius + 7)
                            .stroke(config.iPhoneTint, lineWidth: 10)

                        RoundedRectangle(cornerRadius: cornerRadius + 7)
                            .stroke(.black, lineWidth: 4)

                        RoundedRectangle(cornerRadius: cornerRadius + 3)
                            .stroke(.black, lineWidth: 6)
                            .padding(4)
                    }
                    .padding(-7)

                    /// Permission popup
                    if showPermissionAnimation {
                        animatedAlertView()
                    }
                }
                .frame(width: 402, height: 874)
            }
            .visualEffect { content, proxy in
                let designSize: CGSize = .init(width: 402, height: 874)
                let currentSize = proxy.size
                let ratioX = currentSize.width / designSize.width
                let ratioY = currentSize.height / designSize.height
                let ratio = min(ratioX, ratioY)
                return content.scaleEffect(ratio, anchor: .top)
            }
            .padding(.top, 10)
            .padding(.bottom, 220)
            .frame(maxHeight: .infinity, alignment: .top)
    }

    /// Use keyframe to create animation
    func animatedAlertView() -> some View {
        let fill = Color.primary.opacity(0.15)

        return KeyframeAnimator(initialValue: Frame(), repeating: true) { frame in
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 5)
                    .fill(fill)
                    .frame(width: 120, height: 15)
                    .padding(.bottom, 12)

                RoundedRectangle(cornerRadius: 3)
                    .fill(fill)
                    .frame(height: 15)

                RoundedRectangle(cornerRadius: 3)
                    .fill(fill)
                    .frame(height: 15)
                    .padding(.trailing, 50)
                    .padding(.bottom, 30)

                let layout = config.alertButtons == .three ? AnyLayout(VStackLayout(spacing: 10)) : AnyLayout(HStackLayout(spacing: 8))

                layout {
                    ForEach(1 ... config.alertButtons.rawValue, id: \.self) { index in
                        Capsule()
                            .fill(fill)
                            .frame(height: 45)
                            .overlay {
                                if config.activeTap.rawValue == index {
                                    Circle()
                                        .fill(.gray.opacity(0.8))
                                        .padding(5)
                                        .opacity(frame.tapOpacity)
                                }
                            }
                            .scaleEffect(config.activeTap.rawValue == index ? frame.tapScale : 1)
                    }
                }
            }
            .frame(width: 280)
            .padding(20)
            .optionalLiquidGlass()
            .opacity(frame.opacity)
            .scaleEffect(frame.scale)
        } keyframes: { _ in
            SpringKeyframe(
                Frame(opacity: 1, scale: 1),
                duration: 0.7,
                spring: .smooth(duration: 0.5, extraBounce: 0),
            )

            SpringKeyframe(
                Frame(opacity: 1, scale: 1, tapOpacity: 1),
                duration: 0.1,
                spring: .smooth(duration: 0.4, extraBounce: 0),
            )

            SpringKeyframe(
                Frame(opacity: 1, scale: 1, tapOpacity: 1, tapScale: 0.9),
                duration: 0.2,
                spring: .smooth(duration: 0.4, extraBounce: 0),
            )

            SpringKeyframe(
                Frame(opacity: 1, scale: 1),
                duration: 0.4,
                spring: .smooth(duration: 0.4, extraBounce: 0),
            )

            SpringKeyframe(
                Frame(),
                duration: 2,
                spring: .smooth(duration: 0.4, extraBounce: 0),
            )
        }
    }

    var foreground: Color {
        colorScheme == .dark ? .white : .black
    }

    var background: Color {
        colorScheme != .dark ? .white : .black
    }

    enum Buttons: Int, CaseIterable {
        case two = 2
        case three = 3
    }

    enum ActiveTap: Int, CaseIterable {
        case one = 1
        case two = 2
        case three = 3
    }

    @Animatable
    fileprivate struct Frame {
        var opacity: CGFloat = 0
        var scale: CGFloat = 1.1
        var tapOpacity: CGFloat = 0
        var tapScale: CGFloat = 1
    }

    /// Config
    struct Config {
        var iPhoneTint: Color = .gray
        var buttonTint: Color = .blue
        var title: String
        var description: String
        var initialDelay: CGFloat = 0
        var alertButtons: Buttons
        var activeTap: ActiveTap
        var primaryTitle: String
        var primaryAction: () -> Void
        var secondaryTitle: String?
        var secondaryAction: (() -> Void)?
    }
}

private extension View {
    /// optional liquid glass to support iOS18
    @ViewBuilder
    func optionalLiquidGlass() -> some View {
        if #available(iOS 26, *) {
            self
                .glassEffect(.clear, in: .rect(cornerRadius: 30))
        } else {
            background {
                ZStack {
                    RoundedRectangle(cornerRadius: 30)
                        .fill(.background)
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(.gray.opacity(0.4), lineWidth: 1)
                }
            }
        }
    }
}

#Preview {
    PermissionOnboarding(
        config: .init(
            iPhoneTint: .gray,
            buttonTint: .blue,
            title: "Stay Connected with\nPush Notifications",
            description: dummyDescription,
            initialDelay: 0.5,
            alertButtons: .two,
            activeTap: .two,
            primaryTitle: "Continue",
            primaryAction: {},
            secondaryTitle: "Ask me Later",
            secondaryAction: {}
        )
    )
}
