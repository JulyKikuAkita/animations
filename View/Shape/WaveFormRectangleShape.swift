//
//  WaveFormRectangleShape.swift
//  animation
//
//  Learning point
//  ──────────────
//  Render an audio waveform as a `Shape` — one tiny rectangle per
//  sample, packed left-to-right. By being a `Shape` (not a `View`
//  built from `ForEach`), the waveform can be:
//    • Filled with any `ShapeStyle` (gradient, hierarchy, material).
//    • `.stroke`d, `.trim`med, masked, or used as a mask itself.
//    • Drawn cheaply — one `Path` rather than N independent leaves.
//
//  How the layout works
//  ────────────────────
//    • `samples`  — normalised [0, 1] amplitudes from the audio source.
//    • `width`    — the bar width per sample.
//    • `spacing`  — gap between consecutive bars.
//    • `xCoor`    — running X cursor; advances `width + spacing` per sample.
//    • Each bar's height = `sample * rect.height` (with a 1pt floor so
//      silent samples still register as a thin line, not nothing).
//    • Bars are drawn centred vertically: built around y=0 and then the
//      whole path is shifted by `rect.height / 2` via `offsetBy(dx:dy:)`.
//      This is why each rect's origin uses `y: -sampleHeight / 2`.
//
//  `nonisolated` on `path(in:)` — why?
//  ───────────────────────────────────
//  `Shape.path(in:)` may be called from any actor context during layout
//  passes; marking it `nonisolated` declares it safe to invoke off the
//  main actor. Required because the surrounding type can have
//  main-actor-isolated state otherwise.
//
//  Key APIs
//  ────────
//  • `Path.addRect` — cheapest primitive; fastest path-builder per leaf.
//  • `Path.offsetBy(dx:dy:)` — translate the whole accumulated path
//    after construction (cleaner than rewriting every coordinate).
//  • `Shape` (animatable via `animatableData`) — could animate
//    individual `samples` if you wanted bars to grow/shrink.
//
//  How to apply
//  ────────────
//  • Audio scrubbers, voice-memo bars, DJ scratch UIs, signal monitors.
//  • Histograms (treat each `sample` as a bucket count).
//  • Generalises to ANY 1-D series-as-bars visualisation.
//
//  See also
//  ────────
//  • View/AudioWaveform/WaveformsScrubber.swift — preview parent that
//    wires real audio samples into this shape.
//  • TabShape.swift — sister custom `Shape` in this folder.
//
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
                // Tip: the `max(_, 1)` floor guarantees that a perfectly
                // silent sample (sample == 0) still draws a 1pt line,
                // so the waveform reads as continuous instead of having
                // gaps where the audio was quiet.
                let sampleHeight: CGFloat = max(CGFloat(sample) * rect.height, 1)
                // Tip: build bars symmetrically around y=0 (origin at
                // `-sampleHeight / 2`) so the final `offsetBy(dy:)`
                // can vertically centre the whole waveform in one shot.
                // Otherwise we'd have to bake the centring into every
                // rect's origin.
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
