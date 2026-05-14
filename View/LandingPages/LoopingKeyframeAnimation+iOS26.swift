//
//  LoopingKeyframeAnimation+iOS26.swift
//  animation
//
//  Created on 5/13/26.
import SwiftUI

let mockPhaseData: [LoopOnBoarding.Phase] = [
    .init(
        symbol: "network.badge.shield.half.filled",
        title: "Secure Network Protection",
        description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
    ),
    .init(
        symbol: "faceid",
        title: "Enable Biometric Authentication",
        description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit;"
    ),
    .init(
        symbol: "key.icloud.fill",
        title: "iCoud Key Security",
        description: "Lorem ipsum dolor sit amet..."
    ),
]
struct LoopOnBoardingDemoView: View {
    @State private var showButton: Bool = false
    var body: some View {
        LoopOnBoarding(
            config: .init(showButtons: showButton),
            phases: mockPhaseData
        ) {}
            .onTapGesture {
                showButton.toggle()
            }
    }
}

struct LoopOnBoarding: View {
    var config: Config = .init()
    var phases: [Phase]
    var onButtonClick: () -> Void

    @State private var startDate: Date = .now
    var body: some View {
        ZStack {
            let safePhaseUpdateAfter = max(config.phaseUpdateAfter, 1)
            /// Each phase animation ceiling is 3s
            let timelineDuration = CGFloat(safePhaseUpdateAfter) * 3.0

            TimelineView(.periodic(from: startDate, by: timelineDuration)) { ctx in
                let diff = Int(startDate.distance(to: ctx.date)) / (safePhaseUpdateAfter * 3)
                let index = diff % phases.count

                ZStack {
                    Image(systemName: phases[index].symbol)
                        .font(.system(size: config.iconSize - 20))
                        .foregroundStyle(config.tint.gradient)
                        .contentTransition(.symbolEffect(.replace.downUp))
                        .frame(width: config.iconSize, height: config.iconSize)
                        .keyframeAnimator(initialValue: 1.0, repeating: true) { content, scale in
                            content
                                .scaleEffect(scale)
                        } keyframes: { _ in
                            let scale = config.iconScale

                            MoveKeyframe(1)
                            /// Bounce effect, total duration 3.0
                            SpringKeyframe(1, duration: 0.25)
                            SpringKeyframe(scale, duration: 0.25)
                            SpringKeyframe(1, duration: 0.25)
                            SpringKeyframe(scale, duration: 0.25)
                            SpringKeyframe(1, duration: 0.25)
                            SpringKeyframe(scale, duration: 0.25)
                            SpringKeyframe(1, duration: 0.25)
                            CubicKeyframe(1, duration: 1.25)
                        }
                        .padding(.bottom, 130)

                    ZStack {
                        ForEach(phases.indices, id: \.self) { phaseIndex in
                            if phaseIndex == index {
                                textContent(phase: phases[phaseIndex])
                                    .transition(
                                        .push(from: .bottom)
                                            .combined(with: .blurReplace)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 15)
                    .padding(.bottom, config.showButtons ? 75 : 10)
                    .animation(.bouncy(duration: 0.8), value: index)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                }
            }

            Rectangle()
                .foregroundStyle(.clear)
                .overlay {
                    ZStack {
                        /// total duration should be 3.0
                        pulseRing(delay: 0, wait: 1)
                        pulseRing(delay: 0.5, wait: 0.5)
                        pulseRing(delay: 1, wait: 0)
                    }
                }
                .padding(.bottom, 130)
        }.overlay(alignment: .bottom) {
            if config.showButtons {
                Button(action: onButtonClick) {
                    Text(config.buttonTitle)
                        .font(.title3)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .optionalGlassButtonStyle()
                .tint(config.tint)
                .padding(.horizontal, 30)
                .padding(.bottom, 10)
                .transition(.asymmetric(insertion: .push(from: .bottom),
                                        removal: .push(from: .top)))
            }
        }
        .background {
            Circle()
                .fill(config.tint.gradient)
                .visualEffect { content, proxy in
                    content
                        .offset(y: proxy.size.height * 1.2)
                }
                .frame(maxWidth: .infinity, alignment: .bottom)
                .blur(radius: 90)
        }
        .animation(.bouncy(duration: 0.8), value: config.showButtons)
    }

    private func textContent(phase: Phase) -> some View {
        VStack(alignment: .center, spacing: 12) {
            Text(phase.title)
                .font(.title2.bold())
                .lineLimit(1)
            Text(phase.description)
                .font(.callout)
                .fontWeight(.medium)
                .foregroundStyle(.gray)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(height: 130)
    }

    private func pulseRing(delay: CGFloat, wait: CGFloat) -> some View {
        let size = config.iconSize / 2
        return KeyframeAnimator(initialValue: Pulse(), repeating: true) { pulse in
            Circle()
                .stroke(config.pulseTint, lineWidth: config.pulseWidth)
                .frame(width: size * pulse.scale, height: size * pulse.scale)
                .opacity((pulse.scale - 1.0) / 3.0)
                .opacity(pulse.opacity)
        } keyframes: { _ in
            let scale = config.pulseScale

            LinearKeyframe(Pulse(), duration: delay)
            LinearKeyframe(Pulse(scale: scale, opacity: 0), duration: 2)
            LinearKeyframe(Pulse(scale: scale, opacity: 0), duration: wait)
        }
    }

    @Animatable
    struct Pulse: Hashable {
        var scale: CGFloat = 1
        var opacity: CGFloat = 1
    }

    struct Config {
        var tint: Color = .blue
        var pulseTint: Color = .blue.opacity(0.65)
        var pulseWidth: CGFloat = 1.3
        var pulseScale: CGFloat = 12

        var iconSize: CGFloat = 100
        var iconScale: CGFloat = 1.25

        var phaseUpdateAfter: Int = 1
        var buttonTitle: String = "Continue"
        var showButtons: Bool = true
    }

    struct Phase: Identifiable {
        private(set) var id: String = UUID().uuidString
        var symbol: String
        var title: String
        var description: String
    }
}

#Preview {
    LoopOnBoardingDemoView()
}
