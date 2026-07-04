//
//  Date.swift
//  animation
//
//  Created on 7/4/26.

import SwiftUI

struct Day: Identifiable {
    var id: String = UUID().uuidString
    var value: Int
    var weekdaySymbol: String
    var date: Date
    var noteFromThisMonth: Bool = false
}

struct Week: Identifiable {
    var id: String = UUID().uuidString
    var days: [Day]

    static func load(from date: Date, value: Int) -> Self {
        var days: [Day] = []
        let calendar = Calendar.current
        let weekdaySymbol = calendar.shortWeekdaySymbols
        let modifiedWeekDate = calendar.date(byAdding: .weekOfMonth, value: value, to: date) ?? .now

        if let interval = calendar.dateInterval(of: .weekOfMonth, for: modifiedWeekDate) {
            let startOfWeek = interval.start
            for index in 0 ..< 7 {
                if let date = calendar.date(byAdding: .day, value: index, to: startOfWeek) {
                    let value = calendar.component(.day, from: date)
                    let symbolIndex = calendar.component(.weekday, from: date) - 1
                    let isCurrentMonth = calendar.isDate(date, equalTo: modifiedWeekDate, toGranularity: .month)

                    days
                        .append(
                            .init(
                                value: value,
                                weekdaySymbol: weekdaySymbol[symbolIndex],
                                date: date,
                                noteFromThisMonth: !isCurrentMonth
                            )
                        )
                }
            }
        }

        return .init(days: days)
    }
}
