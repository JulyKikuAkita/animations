//
//  LocationPermissionFullSheetView.swift
//  animation
//
//  Created on 11/14/25.
//  Standalone demo (not wired into the app's demo browser; preview-only).
//
//  Learning point
//  ──────────────
//  Location-permission onboarding presented as a full-screen cover
//  with a SHRINKING-TO-CARD effect: the host screen content stays
//  visible at the top, scaling down + dimming as the cover rises;
//  the bottom holds the permission prompt copy + buttons + a
//  pulsing pin animation. When the user taps Allow (or, post-denial,
//  "Go to Settings"), the cover dismisses and `authorizationDidChange`
//  fires.
//
//  Three pieces working together:
//    1. `LocationPermissionViewConfig` — pure data struct that
//       lets callers brand the prompt (app name, tints, whether
//       to show the pulsing pin, optional dynamic-island chrome).
//    2. `View.locationPermissionFullScreenCover(...)` — public
//       extension; the one-line API.
//    3. Private `LocationPermissionFullSheetView<ScreenContent>` —
//       the actual implementation; reads `MapLocationManager`
//       (helper file in this folder) for live `CLAuthorizationStatus`
//       and switches button label/behaviour across `notDetermined →
//       authorizedWhenInUse → denied`.
//
//  Three-state primary button
//  ──────────────────────────
//  Same standard pattern as
//  [[View/Notifications/CustomNotificationsView]]:
//    • `.notDetermined` → "Allow Location" → request permission.
//    • `.authorizedWhenInUse` → confirmation copy → dismiss + callback.
//    • `.denied` → "Go to Settings" → opens
//      `UIApplication.openSettingsURLString` via
//      `@Environment(\.openURL)`.
//  ALWAYS include the denied → Settings deep-link or users who tap
//  "Don't Allow" once are stuck forever.
//
//  Key APIs
//  ────────
//  • `MapLocationManager` (helper at
//    `View/Map/LocationManager/LocationManagerHelper.swift`) —
//    `@Observable @MainActor` wrapper around `CLLocationManager`.
//  • `.contentTransition(.numericText())` on the button labels —
//    smooth glyph morph as button text changes between states.
//  • `.fullScreenCover(isPresented:)` + `presentationBackground(.background)`
//    — the cover surface; transparent so the host content shows
//    through during the shrink.
//  • Dynamic Island branch (`config.showsDynamicIsland`) — extends
//    the prompt visual into the device's hardware island for a
//    "system asks you" feel.
//  • `MapLocationManager.requestLocationAccess()` — wraps
//    `requestWhenInUseAuthorization()`.
//
//  How to apply
//  ────────────
//  Use whenever a feature needs location and the cold "system alert
//  with no context" feels too jarring. The shrink-the-host-content
//  effect generalises to OTHER permission types too (notifications,
//  contacts, mic) — copy the cover machinery, swap the manager.
//
//  See also
//  ────────
//  • View/Map/LocationManager/LocationManagerHelper.swift — the
//    `MapLocationManager` consumed here.
//  • View/Map/LocationPickerView.swift — usually paired with this
//    cover; show the cover first, then the picker.
//  • View/Notifications/CustomNotificationsView.swift — same
//    "context before consent" pattern for notification permission.
//  • View/LandingPages/PermissionOnboardingIOS26.swift —
//    permission-prompt onboarding using a different visual idiom.
//
import CoreLocation
import SwiftUI

struct LocationPermissionAnimationDemoView: View {
    let config = LocationPermissionViewConfig(appName: "Nanachi App")
    @State private var show: Bool = false
    var body: some View {
        Button("Show Permission View") {
            show.toggle()
        }
        .locationPermissionFullScreenCover(
            isPresented: $show,
            config: config
        ) {
            Text("Hello, World!")
        } authorizationDidChange: { _ in

        } askLater: {}
    }
}

struct LocationPermissionViewConfig {
    var appName: String
    var tint: Color = .pink
    var mapPinTint: Color = .white
    var mapPulseTint: Color = .white
    var showsMapPinANDPulse: Bool = true
    var dimsScreenContent: Bool = true
    var showsDynamicIsland: Bool = false
    var initialDDelay: Double = 0.35
    var pinAndPulseOffset: CGSize = .zero
}

extension View {
    @ViewBuilder
    func locationPermissionFullScreenCover(
        isPresented: Binding<Bool>,
        config: LocationPermissionViewConfig,
        @ViewBuilder screenContent: @escaping () -> some View,
        authorizationDidChange: @escaping (CLAuthorizationStatus) -> Void,
        askLater: @escaping () -> Void

    ) -> some View {
        fullScreenCover(isPresented: isPresented) {
            LocationPermissionFullSheetView(
                isPresented: isPresented,
                config: config,
                screenContent: screenContent,
                authorizationDidChange: authorizationDidChange,
                askLater: askLater
            )
            .presentationBackground(.background)
        }
    }
}

private struct LocationPermissionFullSheetView<ScreenContent: View>: View {
    @Binding var isPresented: Bool
    var config: LocationPermissionViewConfig
    @ViewBuilder var screenContent: ScreenContent
    var authorizationDidChange: (CLAuthorizationStatus) -> Void
    var askLater: () -> Void

    /// View Properties
    @State private var animate: Bool = false
    @State private var animatePulseAnPin: Bool = false
    @State private var manager: MapLocationManager = .init()
    @Environment(\.openURL) private var openURL

    var body: some View {
        GeometryReader {
            let size = $0.size
            let safeArea = $0.safeAreaInsets
            /// effective screen size after animation
            let resizeHeight = size.height - (280 + safeArea.bottom)
            let scale = resizeHeight / size.height
            let cornerRadius = min(size.height * 0.07, 60)

            ZStack {
                /// Background Action Content
                VStack(spacing: 15) {
                    Text(config.appName)
                        .font(.title2)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    Text("Allow **\(config.appName)** to access your \nlocation while **you're using the app**.")
                        .font(.callout)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)

                    Button {
                        if manager.status == .denied {
                            /// route to settings view
                            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                                openURL(settingsURL)
                            }
                        } else if manager.status == .authorizedWhenInUse {
                            /// Dismiss Action
                            isPresented = false
                            authorizationDidChange(.authorizedWhenInUse)
                        } else {
                            manager.requestLocationAccess()
                        }
                    } label: {
                        Text(mainButtonText)
                            .fontWeight(.medium)
                            .frame(maxWidth: 300)
                            .padding(.vertical, 5)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(config.tint)
                    .padding(.top, 10)
                    .contentTransition(.numericText())

                    let isActingAsText = manager.status == .authorizedWhenInUse || manager.status == .denied
                    Button(subButtonText) {
                        isPresented = false
                        askLater()
                    }
                    /// disable action, make sure view can be dismissed if permission denied
                    /// e.g.,  avoid set to manager.status == .notDetermined
                    .allowsHitTesting(manager.status == .authorizedWhenInUse)
                    .fontWeight(isActingAsText ? .regular : .semibold)
                    .font(isActingAsText ? .caption : .body)
                    .foregroundStyle(.gray)
                    .contentTransition(.numericText())
                }
                .animation(.snappy, value: manager.status)
                .compositingGroup()
                /// animating
                .opacity(animatePulseAnPin ? 1 : 0)
                .blur(radius: animatePulseAnPin ? 0 : 5)
                .offset(y: animatePulseAnPin ? 0 : 60)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 15)
                .padding(.bottom, 10)
                .padding(.top, resizeHeight + safeArea.top + 25)
                /// Taking all available space
                .frame(maxHeight: .infinity, alignment: .center)
                .fontDesign(.rounded)
                .ignoresSafeArea(.all, edges: .bottom)

                /// Resizing window
                Rectangle()
                    .fill(.background)
                    /// prevent current view size change
                    .overlay {
                        screenContent
                            .allowsHitTesting(false)
                    }
                    .overlay {
                        ZStack {
                            if config.dimsScreenContent {
                                Rectangle()
                                    .fill(.black.opacity(animate ? 0.5 : 0))
                            }

                            if config.showsMapPinANDPulse {
                                if animatePulseAnPin {
                                    PulseRingView(tint: config.mapPulseTint, size: 200)
                                        .offset(config.pinAndPulseOffset)
                                        .transition(.blurReplace)
                                }

                                Image(systemName: "pawprint")
                                    .font(.system(size: 50, weight: .bold))
                                    .foregroundStyle(config.mapPinTint.shadow(.drop(radius: 5)))
                                    .rotation3DEffect(
                                        .init(degrees: animatePulseAnPin ? -40 : 0),
                                        axis: (x: 1, y: 0, z: 0)
                                    )
                                    .scaleEffect(animatePulseAnPin ? 1 : 10)
                                    .opacity(animatePulseAnPin ? 1 : 0)
                                    .blur(radius: animatePulseAnPin ? 0 : 5)
                                    .offset(y: -15)
                                    .offset(config.pinAndPulseOffset)
                            }

                            if config.showsDynamicIsland {
                                Capsule()
                                    .fill(.black)
                                    .frame(width: size.width * 0.3, height: 38)
                                    .offset(y: 15)
                                    .opacity(animate ? 1 : 0)
                                    .frame(maxHeight: .infinity, alignment: .top)
                            }
                        }
                    }
                    .clipShape(.rect(cornerRadius: animate ? cornerRadius : 0))
                    .overlay {
                        /// phone like  border
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.primary, lineWidth: 15)
                            .opacity(animate ? 1 : 0)
                    }
                    .scaleEffect(animate ? scale : 1, anchor: .top)
                    .offset(y: animate ? (safeArea.top + 25) : 0)
                    .geometryGroup()
                    .ignoresSafeArea()
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(config.initialDDelay))
            withAnimation(.smooth(duration: 0.45)) {
                animate = true
            }

            try? await Task.sleep(for: .seconds(0.25))
            withAnimation(.smooth(duration: 0.45)) {
                animatePulseAnPin = true
            }
        }
        /// return callback when location manager status updated
        .onChange(of: manager.status) { _, newValue in
            authorizationDidChange(newValue)
        }
    }

    var mainButtonText: String {
        let status = manager.status
        if status == .authorizedWhenInUse {
            return "Dismiss"
        } else if status == .denied {
            return "Go to Settings"
        } else {
            return "Allow Access"
        }
    }

    var subButtonText: String {
        let status = manager.status
        if status == .authorizedWhenInUse {
            return "Start exploring"
        } else if status == .denied {
            return "To continue, please allow location access in Settings or tap to dismiss the sheet."
        } else {
            return "Ask Me Later"
        }
    }
}

#Preview {
    LocationPermissionAnimationDemoView()
}
