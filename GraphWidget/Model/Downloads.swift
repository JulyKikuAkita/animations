//
//  Downloads.swift
//  animation

import SwiftUI

/// App Downloads Model
struct Downloads: Identifiable, Equatable {
    var id: UUID = .init()
    var date: Date
    var value: Int
}

extension Date {
    static func day(_ value: Int) -> Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .day, value: value, to: .now) ?? .now
    }
}

var appDownloads: [Downloads] = [
    .init(date: .day(0), value: 100),
    .init(date: .day(-1), value: 180),
    .init(date: .day(-2), value: 60),
    .init(date: .day(-3), value: 120),
    .init(date: .day(-4), value: 370),
    .init(date: .day(-5), value: 48),
    .init(date: .day(-6), value: 70),
]

var appDownloads1: [Downloads] = [
    .init(date: .day(0), value: 10),
    .init(date: .day(-1), value: 180),
    .init(date: .day(-2), value: 110),
    .init(date: .day(-3), value: 220),
    .init(date: .day(-4), value: 3),
    .init(date: .day(-5), value: 148),
    .init(date: .day(-6), value: 37),
]

var appDownloads2: [Downloads] = [
    .init(date: .day(0), value: 1),
    .init(date: .day(-1), value: 11),
    .init(date: .day(-2), value: 121),
    .init(date: .day(-3), value: 1331),
    .init(date: .day(-4), value: 14641),
    .init(date: .day(-5), value: 1331),
    .init(date: .day(-6), value: 121),
]
