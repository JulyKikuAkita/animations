//
//  EffectViewModifier.swift
//  animation

import SwiftUI

private enum Effect: String, CaseIterable {
    case bounce = "Bounce"
    case breath = "Breath"
    case pulse = "Pulse"
    case rotate = "Rotate"
}

/// switch animation without any duplicated code
struct EffectViewModifierDemo: View {
    @State private var effect: Effect = .bounce
    var body: some View {
        Group {
            Picker("", selection: $effect) {
                ForEach(Effect.allCases, id: \.rawValue) {
                    Text($0.rawValue)
                        .tag($0)
                }
            }
            .pickerStyle(.segmented)
            .padding(15)

            VStack {
                Image(systemName: "heart.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.red.gradient)
                    .modifiers { image in
                        switch effect {
                        case .bounce:
                            image.symbolEffect(.bounce)
                        case .breath:
                            image.symbolEffect(.breathe)
                        case .pulse:
                            image.symbolEffect(.pulse)
                        case .rotate:
                            image.symbolEffect(.rotate)
                        }
                    }

                Rectangle()
                    .modifiers { rectangle in
                        switch effect {
                        case .bounce: rectangle.fill(.blue)
                        case .breath: rectangle.fill(.pink)
                        case .pulse: rectangle.fill(.orange)
                        case .rotate: rectangle.fill(.gray)
                        }
                    }
                    .frame(width: 50, height: 20)
            }
        }
    }
}

private extension View {
    @ViewBuilder
    func modifiers(@ViewBuilder content: @escaping (Self) -> some View) -> some View {
        /// since we are passing self, we can also utilize fill() modifier
        content(self)
    }
}

#Preview {
    EffectViewModifierDemo()
}

/// if without view modifier we'll need a lot of duplicated code to achieve the same result
struct EffectViewModifierDuplicatedCode: View {
    @State private var effect: Effect = .bounce
    var body: some View {
        Group {
            if effect == .bounce {
                Image(systemName: "heart.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.red.gradient)
                    .symbolEffect(.bounce)
            } else if effect == .breath {
                Image(systemName: "heart.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.red.gradient)
                    .symbolEffect(.breathe)
            } else if effect == .pulse {
                Image(systemName: "heart.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.red.gradient)
                    .symbolEffect(.pulse)
            } else {
                Image(systemName: "heart.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.red.gradient)
                    .symbolEffect(.rotate)
            }
        }
    }
}
