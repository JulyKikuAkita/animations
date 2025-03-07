//
//  Particle.swift
//  animation

import SwiftUI

/// Particle model for particle animation effect
struct Particle: Identifiable {
    var id: UUID = .init()
    var randomX: CGFloat = 0
    var randomY: CGFloat = 0
    var scale: CGFloat = 1
    var opacity: CGFloat = 1

    mutating func reset() {
        randomX = 0
        randomY = 0
        scale = 0
    }
}

/// Repeatable button Model - keyframe animation
struct ButtonFrame: Identifiable, Equatable {
    var id: UUID = .init()
    var value: Int
    var offset: CGSize = .zero
    var opacity: CGFloat = 1
    var triggerKeyFrame: Bool = false
}
