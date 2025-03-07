//
//  HabitCreationView.swift
//  Habit
import SwiftUI
import UserNotifications

struct HabitCreationView: View {
    var habit: Habit?
    /// View Properties
    @State private var habitName: String = ""
    @State private var frequencies:  [HabitFrequency] = []
    @State private var notificationDate: Date = Date()
    @State private var enableNotifications: Bool = false
    @State private var isNotificationPermissionGranted: Bool = false
    /// Environment Values
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                TextField("Workout for 15 minutes", text: $habitName)
                    .font(.title)
                    .padding(.bottom, 10)

                Text("Habit Frequency")
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .padding(.top, 5)

                HabitCalendarView(
                    isDemo: isNewHabit,
                    createdAt: habit?.createdAt ?? .now,
                    frequency: frequencies,
                    completedDates: habit?.completedDates ?? []
                )
                .applyPaddedBackground(15)

                if isNewHabit {
                    FrequencyPicker()
                        .applyPaddedBackground(10)
                }


                Text("Notifications")
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .padding(.top, 5)

                NotificationProperties()

                HabitCreationButton()
                    .padding(.top, 10)
            }
            .padding(15)
        }
        .animation(.snappy, value: enableNotifications)
        .background(.primary.opacity(0.05))
        .toolbarVisibility(.hidden, for: .navigationBar)
        .onAppear {
            guard let habit else { return }
            habitName = habit.name
            enableNotifications = habit.isNotificationEnabled
            notificationDate = habit.notificationTiming ?? .now
            frequencies = habit.frequencies

        }
        .task {
            isNotificationPermissionGranted =
                (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge])) ?? false
        }

    }

    @ViewBuilder
    func FrequencyPicker() -> some View {
        HStack(spacing: 5) {
            ForEach(HabitFrequency.allCases, id: \.rawValue) { frequency in
                Text(frequency.rawValue.prefix(3))
                    .font(.caption)
                    .hSpacing(.center)
                    .frame(height: 30)
                    .background {
                        if frequencies.contains(frequency) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.fill)
                        }
                    }
                    .contentShape(.rect)
                    .onTapGesture {
                        withAnimation(.snappy) {
                            if frequencies.contains(frequency) {
                                frequencies.removeAll(where: { $0 == frequency })
                            } else {
                                frequencies.append(frequency)
                            }
                        }
                    }

            }
        }
    }

    @ViewBuilder
    func NotificationProperties() -> some View {
        Toggle("Enable Notification", isOn: $enableNotifications)
            .font(.callout)
            .applyPaddedBackground(12)
            .disableWithOpacity(!isNotificationPermissionGranted)

        if enableNotifications && isNotificationPermissionGranted {
            DatePicker("Preferred Reminder Time", selection: $notificationDate, displayedComponents: [.hourAndMinute])
                .applyPaddedBackground(12)
                .transition(.blurReplace)
        }

        if !isNotificationPermissionGranted {
            Text("Notification permission is required to enable reminders. Please enable notifications in your device settings")
                .font(.caption2)
                .foregroundStyle(.gray)
        }
    }

    @ViewBuilder
    func HabitCreationButton() -> some View {
        HStack(spacing: 10){
            Button(action: createHabit) {
                HStack(spacing: 10) {
                    Text( isNewHabit ? "Create Habit" : "Update Habit")
                    Image(systemName: "checkmark.circle.fill")
                }
                .fontWeight(.semibold)
                .hSpacing(.center)
                .foregroundStyle(.white)
                .padding(.vertical, 12)
                .background(.green.gradient, in: .rect(cornerRadius: 10))
                .contentShape(.rect)
            }
            .disableWithOpacity(habitValidation)

            /// Delete habit
            if !isNewHabit {
                Button {
                    guard let habit else { return }
                    dismiss()
                    Task {
                        /// sleep to wait for zoom transition to finish
                        try? await Task.sleep(for: .seconds(0.2))
                        context.delete(habit)
                        try? context.save()
                    }
                } label: {
                    Image(systemName: "trash")
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(14)
                        .background(.red.gradient, in: .circle)
                }
            }
        }
    }


    /// Helpers
    private func createHabit() {
        Task { @MainActor in
            if let habit {
                habit.name = habitName
                cancelNotifications(habit.notificationIDs)
                if enableNotifications {
                    let ids = (try? await scheduleNotifications()) ?? []
                    habit.notificationTiming = notificationDate
                    habit.notificationIDs = ids
                } else {
                    habit.notificationIDs = []
                    habit.notificationTiming = nil
                }
            } else {
                if enableNotifications {
                    let notificationIDs = (try? await scheduleNotifications()) ?? []
                    let habit = Habit(
                        name: habitName,
                        frequency: frequencies,
                        notificationIDs: notificationIDs,
                        notificationTiming: notificationDate
                    )
                    context.insert(habit)

                } else {
                    let habit = Habit(name: habitName, frequency: frequencies)
                    context.insert(habit)
                }

            }

            try? context.save()
            dismiss()
        }
    }

    private func cancelNotifications(_ ids: [String]) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    /// create notifications and return it's ids
    private func scheduleNotifications() async throws -> [String] {
        var notificationIDs: [String] = []
        let weekdaySymbols: [String] = Calendar.current.weekdaySymbols

        let content = UNMutableNotificationContent()
        content.title = "Habit Reminder"
        content.body = "Time for \(habitName)"

        for frequency in frequencies {
            let hour = Calendar.current.component(.hour, from: notificationDate)
            let minute = Calendar.current.component(.minute, from: notificationDate)
            let id: String = UUID().uuidString

            if let dayIndex = weekdaySymbols.firstIndex(of: frequency.rawValue) {
                var scheduleDateComponents = DateComponents()
                scheduleDateComponents.weekday = dayIndex + 1
                scheduleDateComponents.hour = hour
                scheduleDateComponents.minute = minute

                let trigger = UNCalendarNotificationTrigger(dateMatching: scheduleDateComponents, repeats: true)
                let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                try await UNUserNotificationCenter.current().add(request)

                notificationIDs.append(id)
            }

        }
        return notificationIDs
    }

    var habitValidation: Bool {
        frequencies.isEmpty && habitName.isEmpty
    }

    var isNewHabit: Bool  {
        habit == nil
    }
}

#Preview {
    HabitCreationView()
}
