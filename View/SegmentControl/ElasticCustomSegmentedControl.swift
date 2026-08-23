//
//  ElasticCustomSegmentedControl.swift
//  animation
//
//  Created on 7/18/26.
//
//  Learning point
//  ──────────────
//  A segmented control whose active-tab pill behaves like it's on an
//  elastic band: dragging it stretches the capsule toward your finger
//  (only the edge you're dragging past moves) instead of translating as a
//  rigid block, then it snaps to the nearest tab on release.
//
//  Mechanics — two capsules driven by the same offset math
//  ─────────────────────────────────────────────────────────
//    1. Two capsule layers share one frame/offset: a background
//       `Capsule().fill(...)` (the visible indicator) and a `.mask` inside
//       an `.overlay` that reveals the active-tint label copy only where
//       the capsule sits. Both apply identical stretch/offset math, or the
//       mask and the indicator drift apart during a drag.
//    2. Stretch direction is asymmetric padding on the capsule itself:
//       `.padding(.trailing, offsetX > 0 ? -offsetX : 0)` and
//       `.padding(.leading, offsetX < 0 ? offsetX : 0)`. Only the side
//       you're dragging toward ever moves, so the capsule grows out of its
//       anchored edge rather than sliding as a block.
//    3. `YScale` (`abs(offsetX) / (size.width * 0.6) * 0.2`) drives
//       `.scaleEffect(y: 1 - YScale)` on both capsules: the further you
//       drag, the more the pill squashes vertically, reading as tension in
//       the "band" rather than a flat horizontal stretch.
//    4. The drag gesture runs in a named coordinate space (`"CONTROL"`)
//       with `minimumDistance: 0` so taps and drags land in the same
//       handler. `onChanged` clamps `translation + currentOffset` to
//       `(0, size.width - capsuleWidth)` so the capsule can't stretch past
//       the first/last tab. `onEnded` disambiguates by distance: under 5pt
//       is a tap (`update(location:)` picks the tab under the finger),
//       anything larger snaps to the nearest tab (`endTranslation`, via
//       `.rounded()` on `(offset + currentOffset) / capsuleWidth`).
//
//  Key APIs
//  ────────
//  • `.mask(alignment:)` inside `.overlay` — swaps label tint only under
//    the capsule instead of animating color per tab.
//  • `DragGesture(minimumDistance: 0, coordinateSpace: .named(...))` — one
//    gesture handles both tap-to-select and drag-to-drag.
//  • `optionalPillGlassEffect` (`View+Compat.swift`) — iOS 26 liquid glass
//    tint with a no-op fallback below 26, so this control degrades
//    gracefully without an `#available` branch here.
//
//  How to apply
//  ────────────
//  Reuse "same offset math on two layers" for any drag-to-pick control
//  where a filled indicator and a masked foreground must move in lockstep.
//  The asymmetric leading/trailing padding is the reusable idea for an
//  elastic (vs. rigid) drag feel — only the edge in the drag direction
//  moves.

import SwiftUI

struct ElasticCustomSegmentedControlDemo: View {
    @State private var activeTab: SimpleTabs = .all
    var body: some View {
        VStack {
            ElasticSegmentedControl(selection: $activeTab) { tab in
                Text(tab.rawValue)
                    .font(.callout)
                    .fontWeight(.medium)
            }
        }
        .padding(15)
    }
}

struct ElasticSegmentConfig {
    var activeTint: Color = .white
    var inactiveTint: Color = .gray
    var capsuleTint: Color = .blue
    var backgroundTint: Color = .blue.opacity(0.18) /// liquid glass background
    var animation: Animation = .snappy(duration: 0.2, extraBounce: 0)
}

struct ElasticSegmentedControl<Value: CaseIterable, Label: View>: View where Value: Hashable {
    var config: ElasticSegmentConfig = .init()
    @Binding var selection: Value
    @ContentBuilder var label: (Value) -> Label
    /// View Properties
    @State private var offsetX: CGFloat = 0
    var body: some View {
        GeometryReader {
            let size = $0.size
            let capsuleWidth = size.width / CGFloat(tabs.count)
            let currentOffset = CGFloat(tabs.firstIndex(of: selection) ?? 0) * capsuleWidth
            /// Background Y-Scale shrink effect to create drag + stretch visual effect
            let YScale = (abs(offsetX) / (size.width * 0.6)) * 0.2

            tabsView(config.inactiveTint, capsuleWidth: capsuleWidth, height: size.height)
                /// active tint mask — geometry must mirror the indicator
                /// capsule below, or the tint reveal drifts from the pill
                .overlay(alignment: .leading) {
                    tabsView(config.activeTint, capsuleWidth: capsuleWidth, height: size.height)
                        .mask(alignment: .leading) {
                            Capsule()
                                .padding(.trailing, offsetX > 0 ? -offsetX : 0)
                                .padding(.leading, offsetX < 0 ? offsetX : 0)
                                .frame(width: capsuleWidth)
                                .padding(.leading, currentOffset)
                                .scaleEffect(y: 1 - YScale)
                        }
                }
                /// Indicator — kept in lockstep with the mask above
                .background(alignment: .leading) {
                    Capsule()
                        .fill(config.capsuleTint.gradient)
                        /// Extending shape based on offset direction
                        .padding(.trailing, offsetX > 0 ? -offsetX : 0)
                        .padding(.leading, offsetX < 0 ? offsetX : 0)
                        .frame(width: capsuleWidth, height: size.height)
                        .padding(.leading, currentOffset)
                        .scaleEffect(y: 1 - YScale)
                }
                .contentShape(.capsule)
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .named("CONTROL"))
                        .onChanged { value in
                            let translation = value.translation.width
                            /// Limiting between leading and trailing edges
                            let condition = translation + currentOffset
                            guard condition > 0, condition < (size.width - capsuleWidth) else { return }

                            offsetX = translation
                        }
                        .onEnded { value in
                            /// Use dragGesture (not Tap) to handle pill interactions
                            let translation = abs(value.translation.width)
                            if translation < 5 {
                                update(location: value.location.x, capsuleWidth: capsuleWidth)
                            } else {
                                endTranslation(capsuleWidth: capsuleWidth, currentOffset: currentOffset)
                            }
                        }
                )
        }
        .coordinateSpace(.named("CONTROL"))
        .frame(height: 35)
        .optionalPillGlassEffect(config.backgroundTint, in: .capsule)
    }

    @ContentBuilder
    private func tabsView(_ tint: Color, capsuleWidth: CGFloat, height: CGFloat) -> some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.self) { tab in
                label(tab)
                    .foregroundStyle(tint)
                    .lineLimit(1)
                    .frame(width: capsuleWidth, height: height)
                    .clipShape(.capsule)
                    .allowsHitTesting(false)
            }
        }
    }

    private func update(location: CGFloat, capsuleWidth: CGFloat) {
        /// Using location to identify index then move to currently tapped index
        let index = Int(location / capsuleWidth)
        let dropIndex = max(min(index, tabs.count - 1), 0)
        withAnimation(config.animation) {
            selection = tabs[dropIndex]
            offsetX = 0
        }
    }

    private func endTranslation(capsuleWidth: CGFloat, currentOffset: CGFloat) {
        let index = ((offsetX + currentOffset) / capsuleWidth).rounded()
        let dropIndex = max(min(Int(index), tabs.count - 1), 0)

        withAnimation(config.animation) {
            selection = tabs[dropIndex]
            offsetX = 0
        }
    }

    private var tabs: [Value] {
        Array(Value.allCases)
    }
}

#Preview {
    ElasticCustomSegmentedControlDemo()
}
