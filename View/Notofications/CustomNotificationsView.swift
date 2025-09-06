//
//  CustomNotificationsView.swift
//  animation
//
//  Created on 9/6/25.
//  iOS 26
//
import SwiftUI

struct NotificationOnboardingDemoView: View {
    var body: some View {
        let config = NotificationOnboardingConfig(
            title: "You got pinged",
            content: "Click to see Lorem Ipsum text of the printing and typesetting industry",
            notifacationTitle: "Made In Abyss",
            notificationContent: dummyDescription,
            primaryButtonTitle: "Continue",
            secondaryButtonTitle: "Ask Me Later"
        )

        NotificationOnboardingView(config: config) {} onPermissionChange: { _ in

        } onPrimaryButtonTapped: {} onSecondaryButtonTapped: {} onFinish: {}
    }
}

struct NotificationOnboardingConfig {
    var title: String
    var content: String
    var notifacationTitle: String
    var notificationContent: String
    var primaryButtonTitle: String
    var secondaryButtonTitle: String
}

struct NotificationOnboardingView<NotificationLogo: View>: View {
    var config: NotificationOnboardingConfig
    @ViewBuilder var notificationLogo: NotificationLogo
    var onPermissionChange: (_ isApproved: Bool) -> Void
    var onPrimaryButtonTapped: () -> Void
    var onSecondaryButtonTapped: () -> Void
    var onFinish: () -> Void
    /// View Properties
    @Environment(\.colorScheme) private var colorScheme
    @State private var animatedNotification: Bool = false
    @State private var loopContinue: Bool = true
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                iPhonePreview()
                    .padding(.top, 15)
                VStack(spacing: 20) {
                    Text(config.title)
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(config.content)
                        .font(.callout)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 0)

                    Button {} label: {
                        Text(config.primaryButtonTitle)
                            .fontWeight(.medium)
                            .foregroundStyle(foregroundColor)
                            .frame(height: 55)
                            .background(backgroundColor, in: .rect(cornerRadius: 20))
                    }

                    Button {
                        onSecondaryButtonTapped()
                    } label: {
                        Text(config.secondaryButtonTitle)
                            .fontWeight(.semibold)
                            .background(backgroundColor)
                    }
                }
                .padding(.horizontal, 15)
                .padding(.bottom, 20)
            }
        }
        .onDisappear {
            loopContinue = false
        }
    }

    var backgroundColor: Color {
        colorScheme == .dark ? .white : .black
    }

    var foregroundColor: Color {
        colorScheme != .dark ? .white : .black
    }

    private func iPhonePreview() -> some View {
        GeometryReader { proxy in
            let size = proxy.size
            /// scaling view size for smaller phone screen
            let scale = min(size.height / 340, 1)
            let width: CGFloat = 320
            let cornerRadius: CGFloat = 30

            ZStack(alignment: .top) {
                DummyWidgetGridView(totalItems: 15,
                                    backgroundColor: backgroundColor,
                                    showFrame: true)
                DummyStatusBar()
                notificationView()
            }
            .frame(width: width)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .mask {
                LinearGradient(stops: [
                    .init(color: .white, location: 0),
                    .init(color: .clear, location: 0.9),
                ], startPoint: .top, endPoint: .bottom)
                    .padding(-1) /// show border
            }
            .scaleEffect(scale, anchor: .top)
        }
    }

    private func notificationView() -> some View {
        HStack(alignment: .center, spacing: 8) {
            notificationLogo

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(config.notifacationTitle)
                        .font(.callout)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    Spacer(minLength: 0)

                    Text(config.notificationContent)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.gray)
                        .lineLimit(2)
                }
                .padding(12)
                .background(.background)
                .clipShape(.rect(cornerRadius: 20))
                .shadow(color: .gray.opacity(0.5), radius: 1.5)
                .padding(.horizontal, 12)
                .padding(.top, 40)
                .offset(y: animatedNotification ? 0 : -200)
                .clipped()
                .task {
                    await loopAnimation()
                }
            }
        }
    }

    private func loopAnimation() async {
        try? await Task.sleep(for: .seconds(0.5))
        withAnimation(.smooth(duration: 1)) {
            animatedNotification = true
        }
        try? await Task.sleep(for: .seconds(4))
        withAnimation(.smooth(duration: 1)) {
            animatedNotification = false
        }
        guard loopContinue else { return }
        try? await Task.sleep(for: .seconds(1.3))
        await loopAnimation()
    }
}
