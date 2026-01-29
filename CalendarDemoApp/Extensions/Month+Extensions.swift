//
//  Month+Extensions.swift
//  animation
//
//  Created on 1/23/26.

import SwiftUI

extension [CalendarMonth] {
    /// Getting past / future months
    func createMonths(_ count: Int, isPast: Bool) -> [CalendarMonth] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

        guard let month = isPast ? self.first?.date : self.last?.date else {
            return []
        }

        var newMonths: [CalendarMonth] = []

        for index in 1 ... count {
            let offset = isPast ? -index : index
            if let date = calendar.date(byAdding: .month, value: offset, to: month) {
                let name = formatter.string(from: date)
                let weeks = date.weeksInMonth
                let month = CalendarMonth(name: name, date: date, weeks: weeks)

                if isPast {
                    /// Past month should be append in reversed order, 7 -> 6 -> 5 -> 4 for smooth scroll
                    newMonths.insert(month, at: 0)
                } else {
                    newMonths.append(month)
                }
            }
        }
        return newMonths
    }
}
