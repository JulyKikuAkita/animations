//
//  AnimatedSpinnerView.swift
//  animation
import SwiftUI

struct AnimatedSpinnerView: View {
    var tint: Color
    var linedWidth: CGFloat = 4
    @State private var rotation: Double = 0
    @State private var extraRotation: Double = 0
    @State private var isAnimating: Bool = false
    var body: some View {
        ZStack {
            Circle()
                .stroke(tint.opacity(0.3), style: .init(lineWidth: linedWidth, lineCap: .round, lineJoin: .round))

            Circle()
                .trim(from: 0, to: 0.3)
                .stroke(tint, style: .init(lineWidth: linedWidth, lineCap: .round, lineJoin: .round))
                .rotationEffect(.init(degrees: rotation))
                .rotationEffect(.init(degrees: extraRotation))
        }
        .compositingGroup()
        .onAppear(perform: animate)
    }

    private func animate() {
        guard !isAnimating else { return }
        isAnimating = true

        withAnimation(.linear(duration: 0.7).speed(1.2).repeatForever(autoreverses: false)) {
            rotation += 360
        }

        withAnimation(.linear(duration: 1).speed(1.2).delay(1).repeatForever(autoreverses: false)) {
            extraRotation += 360
        }
    }
}

#Preview {
    AnimatedSpinnerView(tint: .green, linedWidth: 4)
        .frame(width: 30, height: 30)
}
