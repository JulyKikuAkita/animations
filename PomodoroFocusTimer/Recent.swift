//
//  Recent.swift
//  demoApp
//
//  Swift Data Model
//

import SwiftData
import SwiftUI

@Model
class Recent {
    var hours: Int
    var minutes: Int
    var seconds: Int
    var date: Date = Date() /// for sorting list
    ///
    init(hours: Int, minutes: Int, seconds: Int) {
        self.hours = hours
        self.minutes = minutes
        self.seconds = seconds
    }

    var totalInSeconds: Int {
        (hours * 60 * 60) + (minutes * 60) + seconds
    }
}
