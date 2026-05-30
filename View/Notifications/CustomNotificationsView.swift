//
//  CustomNotificationsView.swift
//  animation
//
//  Created on 9/6/25.
//  Standalone demo (not wired into the app's demo browser; preview-only).
//  Works on iOS 17+; padding/offset constants branch on `isiOS26OrLater`
//  because the system permission alert layout shifted in iOS 26.
//
//  Note: `@Environment(\.openURL)` for `UIApplication.openNotificationSettingsURLString`
//  works in the iOS 26 simulator; iOS < 26 needs a real device for
//  the deep-link to actually open Settings.
//
//  TODO: Cleanup candidates
//        1. Typo in property names — used in multiple places; do a
//           project-wide rename when you're ready:
//             • `notifacationTitle` → `notificationTitle`
//               (declared in `NotificationOnboardingConfig`, used in
//               the iPhone preview Text).
//             • `askPermisisons` → `askPermissions` (@State + 4 usages).
//        2. Dead `// @main` + `NotificationDemo: App` below — leftover
//           from when this file shipped as its own target. Same
//           pattern as in
//           `View/PhotosView/AsyncImageViewerView+SkeletonviewDemo.swift`
//           — either re-enable as `@main` or delete.
//
//  Learning point
//  ──────────────
//  Notification-permission onboarding screen: live phone preview at
//  the top loops a fake notification animation while the bottom half
//  pitches the value prop. Tapping "Continue" dims the screen, fades
//  in a giant ↑ arrow, and triggers the SYSTEM
//  `requestAuthorization` alert — the arrow points at the system
//  alert's "Allow" button so the user knows where to tap. This is
//  the standard "context before consent" pattern that converts
//  better than asking cold.
//
//  Three-state primary button (label + behaviour driven by
//  `UNAuthorizationStatus`):
//    • `.notDetermined` → "Continue" → ask permission (with the
//      arrow + dim choreography).
//    • `.authorized`   → "You are all set." → calls `onPrimaryButtonTapped`.
//    • `.denied`       → "Go to settings" → opens
//      `UIApplication.openNotificationSettingsURLString` via
//      `@Environment(\.openURL)`.
//
//  Loop animation note: `loopAnimation()` re-invokes itself with
//  `await loopAnimation()` after a sleep. Each iteration is
//  async-suspended at a sleep boundary, so the recursion isn't a
//  growing stack — it's a chain of tasks. Stops cleanly via
//  `loopContinue = false` on disappear.
//
//  Key APIs
//  ────────
//  • `UNUserNotificationCenter.current().notificationSettings()`
//    — read current authorization (the source of truth for the
//    three-state button).
//  • `UNUserNotificationCenter.current().requestAuthorization(options:)`
//    — fires the system permission alert. Note the `try?` /
//    `?? false` pattern: a denial throws on some iOS versions, so
//    we coalesce to a Bool we can pass to `onPermissionChange`.
//  • `@Environment(\.openURL)` + `UIApplication.openNotificationSettingsURLString`
//    — deep-link to the app's notification settings (the only way
//    to recover from `.denied`).
//  • `blurOpacity(_:)` — file-private extension that combines
//    opacity + blur for the dim/arrow appear/disappear; reused on
//    the main content too.
//  • `compositingGroup()` — used inside `blurOpacity` so the blur
//    + opacity apply to the GROUP, not the individual leaf views
//    (otherwise text inside the screen would blur independently
//    of its background).
//
//  How to apply
//  ────────────
//  Use as the template for ANY system-permission onboarding —
//  notifications, location, contacts, mic. The arrow + dim
//  choreography generalises: it points at the system alert,
//  which always animates in from the top centre, so the offset
//  in `.offset(x: ..., y: 150)` lines up across most devices.
//  Always include the `.denied → Settings deep-link` branch, or
//  users who tapped "Don't Allow" once will be permanently stuck.
//
//  See also
//  ────────
//  • View/LandingPages/PermissionOnboardingIOS26.swift — sibling
//    iOS 26-only onboarding for the same kind of permission flow.
//  • Any UNUserNotificationCenter setup in `Helpers/` for the actual
//    request/scheduling logic.
//
import SwiftUI
import UserNotifications

// TODO: Dead — `// @main` is commented out; this `App` is never
//       used. Same leftover-target pattern as the SkeletonviewDemo.
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
