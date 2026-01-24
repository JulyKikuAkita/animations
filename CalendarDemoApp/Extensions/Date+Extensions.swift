//
//  Date+Extensions.swift
//  animation
//
//  Created on 1/23/26.
import SwiftUI

extension Date {
    /// Return 10 months from the current date
    var initialLoadMonths: [Month] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

        var months: [Month] = []
        for offset in -5 ... 4 {
            if let date = calendar.date(byAdding: .month, value: offset, to: self) {
                let monthName = formatter.string(from: date)
                let weeks = date.weeksInMonth
                let month = Month(name: monthName, date: date, weeks: weeks)
                months.append(month)
            }
        }
        return months
    }

    /// Extracting month's week from the given date
    var weeksInMonth: [Week] {
        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: self),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start)
        else {
            return []
        }

        var weeks: [Week] = []
        var currentDate = monthFirstWeek.start

        while currentDate < monthInterval.end {
            var days: [Day] = []

            for index in 0 ..< 7 {
                if calendar.isDate(currentDate, equalTo: self, toGranularity: .month) {
                    let value = calendar.component(.day, from: currentDate)
                    let day = Day(value: value, date: currentDate, isPlaceholder: false)
                    days.append(day)
                } else {
                    /// place holder
                    days.append(.init(isPlaceholder: true))
                }

                /// Updating current date
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            }
            let week = Week(days: days)
            weeks.append(week)
        }

        if let lastIndex = weeks.indices.last {
            weeks[lastIndex].isLast = true
        }
        return weeks
    }
}
