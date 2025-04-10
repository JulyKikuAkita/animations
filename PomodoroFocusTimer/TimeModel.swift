//
//  TimeModel.swift
//  demoApp

import SwiftUI

struct Time: Hashable {
    var hours: Int = 0
    var minutes: Int = 0
    var seconds: Int = 0

    /// if timer is set
    var isZero: Bool {
        hours == 0 && minutes == 0 && seconds == 0
    }

    var totalInSeconds: Int {
        (hours * 60 * 60) + (minutes * 60) + seconds
    }
}
