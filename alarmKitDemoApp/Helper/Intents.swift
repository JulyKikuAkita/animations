//
//  Intents.swift
//  alarmKitDemoApp
//
//  Created on 6/19/25.

import AlarmKit
import AppIntents
import Foundation

struct AlarmActionIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Alarm Action"
    static var isDiscoverable: Bool = false

    @Parameter
    var id: String

    @Parameter
    var isCancel: Bool

    @Parameter
    var isResume: Bool

    init(id: UUID, isCancel: Bool = false, isResume: Bool = false) {
        self.id = id.uuidString
        self.isCancel = isCancel
        self.isResume = isResume
    }

    init() {}

    func perform() async throws -> some IntentResult {
        if let alarmId = UUID(uuidString: id) {
            if isCancel {
                try AlarmManager.shared.cancel(id: alarmId)
            } else {
                if isResume {
                    try AlarmManager.shared.resume(id: alarmId)
                } else {
                    /// Pause
                    try AlarmManager.shared.pause(id: alarmId)
                }
            }
        }
        return .result()
    }
}
