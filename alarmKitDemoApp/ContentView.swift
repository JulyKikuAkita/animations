//
//  ContentView.swift
//  alarmKitDemoApp
//
//  Created on 6/18/25.
//

import AlarmKit
import AppIntents
import SwiftUI

struct ContentView: View {
    @State private var isAuthorized: Bool = false
    @State private var scheduleDate: Date = .now
    var body: some View {
        NavigationStack {
            Group {
                if isAuthorized {
                    alarmView()
                } else {
                    Text("Allow alrams in Settings to proceed")
                        .multilineTextAlignment(.center)
                        .padding(10)
                        .tryGlassEffect()
                }
            }
            .navigationTitle("AlarmKit Demo")
        }
        .task {
            do {
                try await checkAndAuthorizeAlarm()
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
    }

    private func alarmView() -> some View {
        List {
            Section("Date & Time") {
                DatePicker("", selection: $scheduleDate, displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden()
            }

            Button("Set Alarm") {
                Task {
                    do {
                        try await setAlarm()
                    } catch {
                        debugPrint(error.localizedDescription)
                    }
                }
            }

            Button("Set Countdown Alarm") {
                Task {
                    do {
                        try await setCountDownAlarm()
                    } catch {
                        debugPrint(error.localizedDescription)
                    }
                }
            }
        }
    }

    /// countdown does not require schedule
    /// implement countdown pause/resume do need schduel
    private func setCountDownAlarm() async throws {
        /// Alarm ID
        let id = UUID()

        /// Secondary Alert Button
        let alarmCountdown = Alarm.CountdownDuration(preAlert: 20, postAlert: 10)

        let secondaryButton = AlarmButton(text: "Repeat",
                                          textColor: .white,
                                          systemImageName: "arrow.clockwise")

        /// Alert
        let alert = AlarmPresentation.Alert(
            title: "Time's Up!",
            stopButton: .init(text: "Stop",
                              textColor: .red,
                              systemImageName: "stop.fill"),
            secondaryButton: secondaryButton,
            secondaryButtonBehavior: .countdown
        )

        let countdownPresenation = AlarmPresentation.Countdown(
            /// Your title to be displayed on Liveactivity, Dynamic Island etc.
            title: "Countdown",
            pauseButton: .init(
                text: "Pause",
                textColor: .white,
                systemImageName: "pause.fill"
            )
        )

        let pausedPresentation = AlarmPresentation.Paused(
            /// Paused title to be displayed on Liveactivity, Dynamic Island etc.
            title: "Paused",
            resumeButton: .init(
                text: "Resume",
                textColor: .white,
                systemImageName: "play.fill"
            )
        )
        /// Presentation
        let presentation = AlarmPresentation(
            alert: alert,
            countdown: countdownPresenation,
            paused: pausedPresentation
        )

        /// Attributes
        let attributes = AlarmAttributes<CountDownAttributes>(
            presentation: presentation,
            metadata: .init(),
            tintColor: .orange
        )

        /// Configuration
        let config = AlarmManager.AlarmConfiguration(
            attributes: attributes,
            secondaryIntent: OpenAppIntent(id: id)
        )

        /// Adding alarm to the System
        let _ = try await AlarmManager.shared.schedule(id: id, configuration: config)
    }

    // Creating an alarm alart, presentation,
    // attributes, schedule, configuration, id
    // required schedule
    private func setAlarm() async throws {
        /// Alarm ID
        let id = UUID()

        let secondaryButton = AlarmButton(text: "Go to App",
                                          textColor: .white,
                                          systemImageName: "app.fill")

        /// Alert
        let alert = AlarmPresentation.Alert(
            title: "Time's Up!",
            stopButton: .init(text: "Stop",
                              textColor: .red,
                              systemImageName: "stop.fill"),
            secondaryButton: secondaryButton,
            secondaryButtonBehavior: .custom
        )

        /// Presentation
        let presentation = AlarmPresentation(alert: alert)

        /// Attributes
        let attributes = AlarmAttributes<CountDownAttributes>(
            presentation: presentation,
            metadata: .init(),
            tintColor: .orange
        )

        /// Schedule
        let schedule = Alarm.Schedule.fixed(scheduleDate)

        /// Configuration
        let config = AlarmManager.AlarmConfiguration(
            schedule: schedule,
            attributes: attributes,
            secondaryIntent: OpenAppIntent(id: id)
        )

        /// Adding alarm to the System
        let _ = try await AlarmManager.shared.schedule(id: id, configuration: config)
    }

    private func checkAndAuthorizeAlarm() async throws {
        switch AlarmManager.shared.authorizationState {
        case .authorized:
            isAuthorized = true
        case .notDetermined:
            /// Requesting for authorization
            let status = try await AlarmManager.shared.requestAuthorization()
            isAuthorized = status == .authorized
        case .denied:
            isAuthorized = false
        @unknown default:
            fatalError()
        }
    }
}

#Preview {
    ContentView()
}

struct OpenAppIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Open App"
    static var openAppWhenRun: Bool = true
    static var isDiscoverable: Bool = false

    @Parameter
    var id: String

    init(id: UUID) {
        self.id = id.uuidString
    }

    init() {}

    func perform() async throws -> some IntentResult {
        if let alarmID = UUID(uuidString: id) {
            print(alarmID)
        }
        return .result()
    }
}

extension View {
    @ViewBuilder
    func tryGlassEffect() -> some View {
        if #available(iOS 26.0, tvOS 26.0, *) { self.glassEffect() } else { self }
    }
}
