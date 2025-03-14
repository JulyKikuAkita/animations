//
//  ParticleEffect.swift
//  animation

import SwiftUI

/// Custom view modifier
extension View {
    @ViewBuilder
    func particleEffect(systemImage: String, font: Font, status: Bool, activeTint: Color, inActiveTint: Color, drop: Bool) -> some View {
        modifier(
            ParticleModifier(systemImage: systemImage, font: font, status: status, activeTint: activeTint, inActiveTint: inActiveTint, drop: drop)
        )
    }
}

private struct ParticleModifier: ViewModifier {
    var systemImage: String
    var font: Font
    var status: Bool
    var activeTint: Color
    var inActiveTint: Color
    var drop: Bool = true
    @State private var particles: [Particle] = []

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                ZStack {
                    ForEach(particles) { particle in
                        Image(systemName: systemImage)
                            .foregroundColor(status ? activeTint : inActiveTint)
                            .scaleEffect(particle.scale)
                            .offset(x: particle.randomX, y: drop ? -particle.randomY : particle.randomY)
                            .opacity(particle.opacity)
                            /// only visible when status is active
                            .opacity(status ? 1 : 0)
                            /// making base particles visibility with zero animation
                            .animation(.none, value: status)
                    }
                }
                .onAppear {
                    /// Adding base particles for animation
                    if particles.isEmpty {
                        /// change count as per your wish
                        for _ in 1 ... 15 {
                            let particle = Particle()
                            particles.append(particle)
                        }
                    }
                }
                .onChange(of: status) { _, newValue in
                    if !newValue {
                        /// reset animation
                        for index in particles.indices {
                            particles[index].reset()
                        }
                    } else {
                        for index in particles.indices {
                            /// random x & y offset calculation based on index
                            let total = CGFloat(particles.count)
                            let progress = CGFloat(index) / total

                            let maxX: CGFloat = (progress > 0.5) ? 100 : -100
                            let maxY: CGFloat = 60

                            /// create a v shaped position
                            let randomX: CGFloat = ((progress > 0.5 ? progress - 0.5 : progress) * maxX)
                            let randomY: CGFloat = ((progress > 0.5 ? progress - 0.5 : progress) * maxY) + 35

                            /// min scale: 0.35
                            /// max scale: 1
                            let randomScale: CGFloat = .random(in: 0.35 ... 1)
                            withAnimation(.interactiveSpring(response: 0.6, dampingFraction: 0.7, blendDuration: 0.7)) {
                                let spreadRandomX: CGFloat = (progress < 0.5 ? .random(in: 0 ... 10) : .random(in: -10 ... 0))
                                let spreadRandomY: CGFloat = .random(in: 0 ... 30)
                                particles[index].randomX = randomX + spreadRandomX
                                particles[index].randomY = -randomY - spreadRandomY
                            }

                            /// scaling with ease animation
                            withAnimation(.easeInOut(duration: 0.3)) {
                                particles[index].scale = randomScale
                            }

                            /// Removing particles based on index
                            withAnimation(.interactiveSpring(response: 0.6, dampingFraction: 0.7, blendDuration: 0.7)
                                .delay(0.25 + (Double(index) * 0.005)))
                            {
                                particles[index].scale = 0.001
                            }
                        }
                    }
                }
            }
    }
}

#Preview {
    ParticleEffectsView()
}
