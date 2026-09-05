//
//  ClockView.swift
//  animation
//
//  Created on 9/5/26.

import SwiftUI

struct ClockDemoView: View {
    var body: some View {
        VStack {
            ClockView()
        }
        .frame(width: 250, height: 250)
    }
}

/// Both rings here are built without trigonometry: instead of computing an (x, y) per item,
/// every item is laid out identically at the top edge of a frame that fills the whole dial,
/// then `rotationEffect` spins that frame about its center. Because the rotation pivots on
/// the dial's center, "top edge + N degrees" lands the item on the circle at N degrees.
/// `rotationEffect` is a render-time transform only — it never feeds back into layout, so the
/// enclosing ZStack stays a plain square regardless of how far the children are turned.
struct ClockView: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(UIColor.systemGray5))

            /// Time
            ZStack {
                ForEach(0 ..< 12, id: \.self) {
                    let value = $0 * 2
                    let symbol = value == 0 || value == 6 ? "AM" : (value == 12 || value == 18 ? "PM" : "")
                    let isSymbol = !symbol.isEmpty
                    /// 12 labels over 360°, so one step is 30°. Index 0 stays at the top (12 AM).
                    let rotation = Angle(degrees: Double($0 * 30))

                    HStack(alignment: .bottom, spacing: 0) {
                        Text("\(value % 12 == 0 ? 12 : value % 12)")
                        if isSymbol {
                            Text(symbol)
                                .textScale(.secondary)
                        }
                    }
                    .font(.system(
                        size: isSymbol ? 14 : 12,
                        weight: isSymbol ? .bold : .semibold
                    ))
                    .foregroundStyle(isSymbol ? Color.primary : .gray)
                    /// Pre-rotate the glyph backwards about its own center. This is undone by the
                    /// outer rotation below, so the label reads upright instead of tilting with the
                    /// dial — the difference between clock numerals and text on a spinning wheel.
                    .rotationEffect(-rotation)
                    /// Grow to the dial's full height and pin the label to the top edge. The frame's
                    /// center is now the dial's center, which is what the next rotation pivots on;
                    /// the frame's height is therefore the ring's radius.
                    .frame(maxHeight: .infinity, alignment: .top)
                    /// Rotate the full-height frame, carrying the top-pinned label around the ring.
                    /// Modifiers wrap outward, so this rotation composes with `-rotation` above and
                    /// the two cancel for the glyph itself while the position still moves.
                    .rotationEffect(rotation)
                }
            }
            .overlay {
                VStack {
                    Image(systemName: "moon.fill")
                        .foregroundStyle(.indigo)
                    Spacer()
                    Image(systemName: "sun.max.fill")
                        .foregroundStyle(.yellow)
                }
                .padding(.vertical, 25)
            }
            .padding(20)

            /// Ticks
            ZStack {
                ForEach(0 ..< 60, id: \.self) {
                    /// 60 ticks over 360°, so one step is 6°.
                    let rotation = Angle(degrees: Double($0 * 6))

                    Capsule()
                        .fill(.gray)
                        /// Every 5th tick is taller, marking the hour positions.
                        .frame(width: 2, height: $0 % 5 == 0 ? 6 : 3)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        /// Same top-pin-then-rotate trick as the labels, but with no counter-rotation:
                        /// a tick is supposed to tilt with the dial so it points at the center.
                        .rotationEffect(rotation)
                }
            }
            .padding(5)
        }
    }
}

#Preview {
    ClockDemoView()
}
