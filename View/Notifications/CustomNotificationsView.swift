//
//  CustomNotificationsView.swift
//  animation
//
//  Created on 9/6/25.
//  iOS 26
//
import SwiftUI
import UserNotifications

// @main
struct NotificationDemo: App {
    var body: some Scene {
        WindowGroup {
            NotificationOnboardingDemoView()
        }
    }
}

struct NotificationOnboardingDemoView: View {
    var body: some View {
        let config = NotificationOnboardingConfig(
            title: "Stay Connected with Push Notifications",
            content: "Click to see Lorem Ipsum text of the printing and typesetting industry",
            notifacationTitle: "Made In Abyss",
            notificationContent: dummyDescription,
            primaryButtonTitle: "Continue",
            secondaryButtonTitle: "Ask Me Later"
        )

        NotificationOnboardingView(config: config) {
            Image(systemName: "pc")
                .font(.title2)
                .foregroundStyle(.background)
                .frame(width: 40, height: 40)
                .background(.primary)
                .clipShape(.rect(cornerRadius: 12))
        } onPermissionChange: { _ in

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
    @Environment(\.openURL) private var openURL // ios 26 works on sims; others need real device
    @State private var animatedNotification: Bool = false
    @State private var loopContinue: Bool = true
    @State private var askPermisisons: Bool = false
    @State private var showArrow: Bool = false
    @State private var authorization: UNAuthorizationStatus = .notDetermined
    var body: some View {
        ZStack {
            ZStack {
                Rectangle()
                    .fill(backgroundColor)
                    .ignoresSafeArea()
                    .blurOpacity(askPermisisons)

                Image(systemName: "arrow.up")
                    .font(.system(size: 80, weight: .bold))
                    .foregroundStyle(foregroundColor)
                    /// ios26 has larger button padding so apply different offset
                    .offset(x: isiOS26OrLater ? 75 : 70, y: 150)
                    .blurOpacity(showArrow)
            }
            .allowsHitTesting(false)

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

                    Button {
                        if authorization == .authorized {
                            onPrimaryButtonTapped()
                        } else if authorization == .denied {
                            /// route to settings page
                            if let settingsURL = URL(
                                string: UIApplication.openNotificationSettingsURLString
                            ) {
                                openURL(settingsURL)
                            }
                        } else {
                            askNotificationPermission()
                        }
                    } label: {
                        Text(authorization == .authorized ? "You are all set." :
                            authorization == .denied ? "Go to settings" :
                            config.primaryButtonTitle)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .foregroundStyle(foregroundColor)
                            .frame(height: 55)
                            .background(backgroundColor, in: .rect(cornerRadius: 20))
                    }
                    .geometryGroup()

                    if authorization == .notDetermined {
                        Button {
                            onSecondaryButtonTapped()
                        } label: {
                            Text(config.secondaryButtonTitle)
                                .fontWeight(.semibold)
                                .foregroundStyle(backgroundColor)
                        }
                    }
                }
                .padding(.horizontal, 15)
                .padding(.bottom, 20)
            }
            .blurOpacity(!askPermisisons)
        }
        .onDisappear {
            loopContinue = false
        }
        .task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            let authorization = settings.authorizationStatus
            self.authorization = authorization
            if authorization == .authorized {
                onPermissionChange(true)
            }

            if authorization == .denied {
                onPermissionChange(false)
            }
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

                    Text("Now")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.gray)
                }

                Text(config.notificationContent)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.gray)
                    .lineLimit(2)
            }
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

    private func askNotificationPermission() {
        Task { @MainActor in
            withAnimation(.smooth(duration: 0.3, extraBounce: 0)) {
                askPermisisons = true
            }
            try? await Task.sleep(for: .seconds(0.3))

            withAnimation(.smooth(duration: 0.3, extraBounce: 0)) {
                showArrow = true
            }

            let status = await (
                try? UNUserNotificationCenter
                    .current()
                    .requestAuthorization(
                        options: [.alert, .badge, .sound]
                    )
            ) ?? false
            let authorization = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
            onPermissionChange(status)

            /// remove arrow view + dark background
            withAnimation(.smooth(duration: 0.3, extraBounce: 0)) {
                showArrow = false
                askPermisisons = false
                self.authorization = authorization
            }
        }
    }
}

#Preview {
    NotificationOnboardingDemoView()
}

private extension View {
    func blurOpacity(_ status: Bool) -> some View {
        compositingGroup()
            .opacity(status ? 1 : 0)
            .blur(radius: status ? 0 : 10)
    }
}
