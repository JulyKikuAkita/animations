//
//  Date+Extensions.swift
//  animation
//

import Foundation

extension Date {
    static var currentWeek: [Day] {
        let calendar = Calendar.current
        guard let firstWeekDay = calendar.dateInterval(of: .weekOfMonth, for: .now)?.start else {
            return []
        }

        var week: [Day] = []
        for index in 0 ..< 7 {
            if let day = calendar.date(byAdding: .day, value: index, to: firstWeekDay) {
                week.append(.init(date: day))
            }
        }
        return week
    }

    func string(_ format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }

    func isSame(_ date: Date?) -> Bool {
        guard let date else {
            return false
        }
        return Calendar.current.isDate(self, inSameDayAs: date)
    }

    struct Day: Identifiable, Hashable {
        let id: String = UUID().uuidString
        let date: Date
    }
}
