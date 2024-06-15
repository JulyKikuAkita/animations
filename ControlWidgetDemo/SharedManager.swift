//
//  SharedManager.swift
//  animation
//
//  iOS 18 control widget demo
//  a Singleton model to demo control widget intents

import SwiftUI

class SharedManager {
    static let shared = SharedManager()
    /// control toggle
    var isTurnedOn: Bool = false
    /// control botton
    var caffeineInTake: CGFloat = 0
}
