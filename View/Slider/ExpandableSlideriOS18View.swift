//
//  ExpandableSlideriOS18View.swift
//  animation
//
//  Learning point
//  ──────────────
//  iOS-Music-app style expandable slider: while idle, the slider sits
//  at a slim 20pt height; on touch-down it grows to ~45pt and reveals
//  an overlay (icon + percentage). Releasing collapses it back.
//
//  Three reusable mechanics
//  ────────────────────────
//    1. **Mask-driven height growth** — instead of changing the
//       slider's actual frame (which would re-run layout and bump
//       neighbours), the slider is rendered at full expanded size and
//       MASKED to the current visible height. Layout neighbours never
//       move; only the mask reshapes. See the bottom `.mask { ... }`.
//    2. **`@GestureState` for `isActive`** — auto-resets to `false`
//       when the gesture ends. No manual reset; no race conditions.
//    3. **Two-pass overlay tinting** — the overlay (icon + label) is
//       drawn TWICE: once in `overlayInActiveTint` over the inactive
//       track, once in `overlayActiveTint` masked to the active track
//       width. As the active fill grows, the overlay automatically
//       changes colour where the track is filled — no manual
//       per-pixel logic, all done by mask intersection.
//
//  Why expand via mask, not via `frame` change
//  ───────────────────────────────────────────
//  Changing `frame.height` while animating triggers SwiftUI's normal
//  layout cycle: every sibling reflows, every gesture coord may shift,
//  and the underlying `width = (value/range)*size.width` math sees a
//  size change mid-drag. Animating a mask leaves the inner geometry
//  stable — the slider is "really" at expanded size the whole time;
//  only the visible window changes.
//
//  Animation timing trick
//  ──────────────────────
//  The overlay's appear/disappear uses an *asymmetric* curve:
//
//      .animation(.easeInOut(duration: 0.3)
//                  .delay(isActive ? 0.12 : 0)
//                  .speed(isActive ? 1 : 2))
//
//  → On press (isActive = true): wait 0.12s for the height expansion
//    to play out before the overlay fades in. Looks like the overlay
//    is "revealed" by the growth.
//  → On release (isActive = false): no delay, double speed. The
//    overlay should feel like it's already collapsing as you let go,
//    not lagging behind.
//
//  Key APIs
//  ────────
//  • `@GestureState` — ephemeral state that auto-resets.
//  • `.highPriorityGesture` — wins over the parent's scroll/list
//    gestures, important inside `List` rows.
//  • `.mask { Rectangle().frame(width: width) }` — fill progress
//    via masking, not a separate `Rectangle().frame(...)`. Lets the
//    fill use the same gradient as the track.
//  • `Image(systemName:variableValue:)` — variable-fill SF Symbols
//    (iOS 16+); the speaker icon's fill grows with `volume / 100`.
//
//  How to apply
//  ────────────
//  Use whenever a slider needs touch-state polish: brightness, volume,
//  EV, intensity. The mask-based expansion is the load-bearing trick;
//  the asymmetric animation curve is the polish. Both apply to any
//  "expand on press, contract on release" interaction beyond sliders
//  (toolbar buttons, segmented controls, etc.).
//

import SwiftUI

struct ExpandableSlideriOS18DemoView: View {
    @State private var volume: CGFloat = 30
    var body: some View {
        NavigationStack {
            VStack {
                CustomExpandableSlider(value: $volume, in: 0 ... 100) {
                    /// Overlay view of image and text
                    HStack {
                        Image(systemName: "speaker.wave.3.fill", variableValue: volume / 100)
                        Spacer(minLength: 0)
                        Text(String(format: "%1.f", volume) + "%")
                            .font(.callout)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(15)
            .navigationTitle("Expandable slider")
        }
    }
}

struct CustomExpandableSlider<Overlay: View>: View {
    @Binding var value: CGFloat
    var range: ClosedRange<CGFloat>
    var config: Config
    var overlay: Overlay

    init(
        value: Binding<CGFloat>,
        in range: ClosedRange<CGFloat>,
        config: Config = .init(),
        @ViewBuilder overlay: @escaping () -> Overlay
    ) {
        _value = value
        self.range = range
        self.config = config
        self.overlay = overlay()
        lastStoredValue = value.wrappedValue
    }

    /// View Properties
    @State private var lastStoredValue: CGFloat
    @GestureState private var isActive: Bool = false

    var body: some View {
        GeometryReader {
            let size = $0.size
            let width = (value / range.upperBound) * size.width

            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(config.inActiveTint)

                Rectangle()
                    .fill(config.activeTint)
                    .mask(alignment: .leading) {
                        Rectangle()
                            .frame(width: width)
                    }

                // Tip: two-pass overlay tinting.
                // Render the overlay twice — first in the inactive
                // colour over the empty part of the track, then in the
                // active colour MASKED to the current fill width. As
                // the fill grows the visible overlay colour appears to
                // "follow the boundary" without any per-pixel logic.
                ZStack(alignment: .leading) {
                    overlay
                        .foregroundStyle(config.overlayInActiveTint)

                    overlay
                        .foregroundStyle(config.overlayActiveTint)
                        .mask(alignment: .leading) {
                            Rectangle()
                                .frame(width: width)
                        }
                }
                .compositingGroup() /// group the view to a single view
                // Tip: asymmetric on-press / on-release curve.
                // Press → 0.12s delay (let the height grow first), 1x speed.
                // Release → 0 delay, 2x speed (snap collapse alongside
                // the height shrink). Same `.animation` modifier handles
                // both directions because the durations differ via
                // `.delay` and `.speed`.
                .animation(.easeInOut(duration: 0.3).delay(isActive ? 0.12 : 0).speed(isActive ? 1 : 2)) {
                    $0
                        .opacity(isActive ? 1 : 0)
                }
            }
            .clipShape(.rect(cornerRadius: config.cornerRadius))
            .contentShape(.rect(cornerRadius: config.cornerRadius))
            .highPriorityGesture(
                DragGesture(minimumDistance: 0)
                    .updating($isActive) { _, out, _ in
                        out = true
                    }
                    .onChanged { value in
                        let progress = ((value.translation.width / size.width) * range.upperBound) + lastStoredValue
                        self.value = max(min(progress, range.upperBound), range.lowerBound)
                    }.onEnded { _ in
                        lastStoredValue = value
                    }
            )
        }
        // Tip: render at FULL expanded height, animate the mask only.
        // The slider's actual frame is always `20 + extraHeight`, so its
        // internal geometry (drag math, width %) is stable. The mask
        // shrinks/grows the visible window — surrounding layout never
        // sees a height change, so neighbours don't shift.
        .frame(height: 20 + config.extraHeight)
        .mask {
            RoundedRectangle(cornerRadius: config.cornerRadius)
                .frame(height: 20 + (isActive ? config.extraHeight : 0))
        }
        .animation(.snappy, value: isActive)
    }

    struct Config {
        var activeTint: Color = .primary
        var inActiveTint: Color = .black.opacity(0.06)
        var cornerRadius: CGFloat = 15
        var extraHeight: CGFloat = 25
        /// Overlay Properties
        var overlayActiveTint: Color = .white
        var overlayInActiveTint: Color = .black
    }
}

#Preview {
    ExpandableSlideriOS18DemoView()
}
