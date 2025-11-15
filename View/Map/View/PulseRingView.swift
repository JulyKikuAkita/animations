//
//  PulseRingView.swift
//  animation
//
//  Created on 11/14/25.
//
//  The view only animates when scenePhase signals app in foreground
//  and stop animating in background

import SwiftUI

struct PulseRingView: View {
    var tint: Color
    var size: CGFloat
    /// View Properties
    @State private var animate: [Bool] = [false, false, false]
    @State private var showRings: Bool = false
    @Environment(\.scenePhase) private var phase

    var body: some View {
        ZStack {
            if showRings {
                ZStack {
                    ringView(index: 0)
                    ringView(index: 1)
                    ringView(index: 2)
                }
                .onAppear {
                    for index in 0 ..< animate.count {
                        let delay = Double(index) * 0.2
                        withAnimation(.easeInOut(duration: 2)
                            .repeatForever(autoreverses: false)
                            .delay(delay)
                        ) {
                            animate[index] = true
                        }
                    }
                }
                .onDisappear {
                    animate = [false, false, false]
                }
            }
        }
        .onChange(of: phase, initial: true) { _, newValue in
            showRings = newValue != .background
        }
        .frame(width: size, height: size)
    }

    /// customize as needed
    func ringView(index: Int) -> some View {
        Circle()
            .fill(tint)
            .opacity(animate[index] ? 0 : 0.4)
            .scaleEffect(animate[index] ? 2 : 0)
    }
}

#Preview {
    PulseRingView(tint: .blue, size: 200)
}
