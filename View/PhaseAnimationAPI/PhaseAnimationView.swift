//
//  PhaseAnimationView.swift
//  animation

import SwiftUI

struct PhaseAnimationViewDemo: View {
    @State private var isAnimationEnabled: Bool = false /// workaround to avoid new image slide in from topLeft
    var body: some View {
        ZStack {
            if isAnimationEnabled {
                PhaseAnimator(OSInfo.allCases) { info in
                    VStack(spacing: 10) {
                        ZStack {
                            ForEach(OSInfo.allCases, id: \.rawValue) { osInfo in
                                let isSame = osInfo == info

                                if isSame {
                                    Image(systemName: osInfo.symbolImage)
                                        .font(.system(size: 100, weight: .ultraLight, design: .rounded))
                                        .transition(.blurReplace(.downUp))
                                }
                            }
                        }
                        .frame(height: 120)

                        VStack(spacing: 10) {
                            Text("Available On")
                                .font(.callout)
                                .foregroundStyle(.secondary)

                            ZStack {
                                ForEach(OSInfo.allCases, id: \.rawValue) { osInfo in
                                    let isSame = osInfo == info

                                    if isSame {
                                        Text(osInfo.rawValue)
                                            .font(.largeTitle)
                                            .fontWeight(.semibold)
                                            .fontDesign(.rounded)
                                            .transition(.push(from: .top))
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .clipped()
                        }
                    }
                } animation: { _ in
                    /// delay between each slide
                    .interpolatingSpring(.bouncy(duration: 1, extraBounce: 0)).delay(1.5)
                }
            }
        }
        .task {
            isAnimationEnabled = true
        }
    }
}

#Preview {
    NavigationStack {
        PhaseAnimationViewDemo()
            .navigationTitle("Phase Animator")
            .navigationBarTitleDisplayMode(.inline)
    }
}
