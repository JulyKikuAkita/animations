//
//  WaveFormRectangleShape.swift
//  animation
import SwiftUI

/// Custom WaveForm Shape for audio wave
struct WaveFormShape: Shape {
    var samples: [Float]
    var spacing: Float = 2
    var width: Float = 2
    nonisolated func path(in rect: CGRect) -> Path {
        Path { path in
            var xCoor: CGFloat = 0
            for sample in samples {
                let sampleHeight: CGFloat = max(CGFloat(sample) * rect.height, 1)
                path.addRect(CGRect(
                    origin: .init(x: xCoor + CGFloat(width), y: -sampleHeight / 2),
                    size: .init(width: CGFloat(width), height: sampleHeight)
                ))
                xCoor += CGFloat(spacing + width)
            }
        }
        .offsetBy(dx: 0, dy: rect.height / 2) // center at the hstack
    }
}

#Preview {
    WaveformsScrubberDemoView()
}
