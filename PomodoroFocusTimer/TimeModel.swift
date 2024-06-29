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
        return hours == 0 && minutes == 0 && seconds == 0
    }
}
