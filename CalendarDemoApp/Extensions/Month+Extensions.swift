//
//  Month+Extensions.swift
//  animation
//
//  Created on 1/23/26.

import SwiftUI

extension [Month] {
    /// Getting past / future months
    func createMonths(_ count: Int, isPast: Bool) -> [Month] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

        guard let month = isPast ? self.first?.date : self.last?.date else {
            return []
        }

        var newMonths: [Month] = []

        for index in 1 ... count {
            let offset = isPast ? -index : index
            if let date = calendar.date(byAdding: .month, value: offset, to: month) {
                let name = formatter.string(from: date)
                let weeks = date.weeksInMonth
                let month = Month(name: name, date: date, weeks: weeks)

                if isPast {
                    newMonths.insert(month, at: 0)
                } else {
                    newMonths.append(month)
                }
            }
        }
        return newMonths
    }
}
