//
//  PlayerConfig.swift
//  animation

import SwiftUI

struct PlayerConfig: Equatable {
    var position: CGFloat = .zero
    var lastPosition: CGFloat = .zero
    var progress: CGFloat = 0
    var selectedPlayerItem: PlayerItem?
    var showMiniPlayer: Bool = false
    
    /// Resetting properties
    mutating func resetPosition() {
        position = .zero
        lastPosition = .zero
        progress = .zero
    }
}
