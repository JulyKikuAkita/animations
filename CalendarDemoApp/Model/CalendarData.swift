//
//  CalendarData.swift
//  animation
//
//  Created on 1/23/26.

import SwiftUI

struct CalendarMonth: Identifiable {
    var id: String = UUID().uuidString
    var name: String
    var date: Date
    var weeks: [CalendarWeek]
}

struct CalendarWeek: Identifiable {
    var id: String = UUID().uuidString
    var days: [CalendarDay]
    var isLast: Bool = false
}

struct CalendarDay: Identifiable {
    var id: String = UUID().uuidString
    var value: Int?
    var date: Date?
    var isPlaceholder: Bool
}
