//
//  Habit.swift
//  Habit

import SwiftData
import SwiftUI

@Model
class Habit {
    var name: String
    var frequencies: [HabitFrequency]
    var createdAt: Date = Date()
    var completedDates: [TimeInterval] = []

    /// Notifications Properties
    var notificationIDs: [String] = []
    var notificationTiming: Date?

    /// Zoom Transition
    var uniqueID: String { UUID().uuidString }

    init(name: String, frequency: [HabitFrequency], notificationIDs: [String] = [], notificationTiming: Date? = nil) {
        self.name = name
        frequencies = frequency
        self.notificationIDs = notificationIDs
        self.notificationTiming = notificationTiming
    }

    var isNotificationEnabled: Bool {
        !notificationIDs.isEmpty && notificationTiming != nil
    }
}
