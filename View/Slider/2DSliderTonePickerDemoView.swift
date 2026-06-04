//
//  2DSliderTonePickerDemoView.swift
//  animation
//
//  Created on 3/27/26.
//
//  Learning point
//  ──────────────
//  Recreate the iOS Photos app's "Tone" picker — a 2D slider laid out
//  as a grid of small circles where the touch point causes nearby
//  circles to scale up + brighten in a smooth radial falloff. Idle
//  state shows a row+column highlight cross at the snapped cell;
//  dragging activates the proximity-based "puddle of light" feel.
//
//  Three reusable mechanics
//  ────────────────────────
//    1. **`@GestureState` + `.updating { }` for ephemeral drag state** —
//       `dragLocation` automatically resets to `nil` when the gesture
//       ends, distinguishing "still dragging" from "released" without
//       a manual flag. The `.onChange(of: dragLocation)` handler turns
//       that into start / changed / ended branches.
//    2. **Proximity-driven scale/opacity** — for each cell, compute
//       distance to the touch point, normalise it against
//       `influencesRadius`, and lerp scale/opacity. Quadratic falloff
//       (1 - clamp(d / r)) gives the soft radial puddle without a
//       Metal shader.
//    3. **Bidirectional position ↔ location** — `position` is exposed
//       to the caller in normalised [0,1] × [0,1] space; the view
//       internally tracks pixel `location`. `translateLocationIntoPosition`
//       and `translateLocationIntoLocation` are inverses, with margin
//       compensation (`itemSize / 2` half-cell padding) so the touch
//       point can't leave the visible grid.
//
//  Why a grid of circles, not one Canvas/Metal blob?
//  ─────────────────────────────────────────────────
//  The discrete grid renders crisply at every scale, animates element
//  state cheaply (one `Circle` per cell, fewer than 200 nodes), and
//  composes natively with SwiftUI accessibility / hit testing. A
//  `Canvas` redraw would also work but loses the per-cell diffing.
//
//  Why `.coordinateSpace(name: "POSITIONALPAD")`?
//  ──────────────────────────────────────────────
//  Without a named coordinate space, `value.location` from the gesture
//  would be relative to whichever ancestor space SwiftUI picks. Naming
//  the pad guarantees the X/Y we read is in the pad's own pixel space,
//  matching `config.size`.
//
//  Key APIs
//  ────────
//  • `@GestureState` + `.updating { }` — auto-reset transient state.
//  • `DragGesture(minimumDistance: 0, coordinateSpace: .named(...))` —
//    fire on touch-down, in our coord space.
//  • `.coordinateSpace(name:)` — pin the gesture's coordinate origin.
//  • `.drawingGroup()` — flatten the cell grid into a single GPU
//    bitmap; reduces rasterisation cost when many cells animate.
//
//  How to apply
//  ────────────
//  Use whenever you need a 2D parameter picker (colour mix, tone
//  warmth/tint, joystick, audio pan/depth). The proximity-falloff
//  pattern generalises to any "soft selection" UI — heat maps,
//  influence visualisations, blob editors.
//

import SwiftUI

struct TwoDSliderTonePickerDemoView: View {
    @State private var position: CGPoint = .init(x: 0.5, y: 0.5)
    var body: some View {
        VStack(spacing: 15) {
            Text("[x: \(position.x), y: \(position.y)]")
            Button("Reset") {
                position = .init(x: 0.5, y: 0.5)
            }
            PhotosStylePositionPad(position: $position)
                .padding(20)
                .background {
                    LinearGradient(colors: [
                        .primary, .primary.opacity(0.7),
                    ], startPoint: .top, endPoint: .bottom)
                        .clipShape(.rect(cornerRadius: 30))
                }
        }
    }
}

// swiftlint:disable identifier_name
struct PhotosStylePositionPad: View {
    var config: Config = .init()
    @Binding var position: CGPoint
    /// View Properties
    @State private var rows: [Row] = []
    @State private var activeRow: Int = 0
    @State private var activeColumn: Int = 0

    @GestureState private var dragLocation: CGPoint?
    @State private var isDragging: Bool = false
    @State private var touchPointOffset: CGSize = .zero
    var body: some View {
        VStack(spacing: 0) {
            ForEach(rows) { row in
                HStack(spacing: 0) {
                    ForEach(row.columns) { column in
                        Circle()
                            .fill(config.tint)
                            .frame(width: config.circleSize, height: config.circleSize)
                            .opacity(column.opacity)
                            .scaleEffect(column.scale)
                            .frame(width: itemSize, height: itemSize)
                    }
                }
            }
        }
        .frame(width: config.size, height: config.size)
        .drawingGroup() /// optional
        .overlay(alignment: .topLeading) {
            Circle()
                .fill(config.tint)
                .frame(
                    width: isDragging ? config.touchPointSize : config.circleSize * circleZoom,
                    height: isDragging ? config.touchPointSize : config.circleSize * circleZoom
                )
                .offset(touchPointOffset)
                .frame(width: itemSize, height: itemSize)
        }
        .contentShape(.rect)
        // Tip: `@GestureState` + `.updating` is the ephemeral state pattern.
        // `dragLocation` is automatically `nil` when the gesture is NOT
        // active. That gives us a free "is dragging?" check via
        // `oldValue == nil` / `newValue == nil` in the .onChange below —
        // no manual `isDragging` flag to set/clear from inside the gesture.
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .named("POSITIONALPAD"))
                .updating($dragLocation) { value, out, _ in
                    let location = value.location

                    /// Cap to [itemSize/2, size - itemSize/2] so the touch
                    /// point can't leave the visible cell area.
                    out = .init(
                        x: max(min(location.x, config.size - itemSize / 2), itemSize / 2),
                        y: max(min(location.y, config.size - itemSize / 2), itemSize / 2)
                    )
                }
        )
        .onChange(of: dragLocation) { oldValue, newValue in
            if let newValue { /// Start dragging
                updateActiveRowColumn(location: newValue)
                if oldValue == nil {
                    /// Animating  first change
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isDragging = true
                        createAndUpdateRows(location: newValue, isDragging: true)
                        updateTouchPointOffset(location: newValue)
                    }
                } else {
                    createAndUpdateRows(location: newValue, isDragging: true)
                    updateTouchPointOffset(location: newValue)
                }
                translateLocationIntoPosition(location: newValue)

            } else { /// dragging ends
                if let oldValue {
                    updateActiveRowColumn(location: oldValue)

                    withAnimation(.easeInOut(duration: 0.2)) {
                        isDragging = false
                        createAndUpdateRows(location: oldValue, isDragging: false)
                        updateTouchPointOffset(location: oldValue)
                    }
                    translateLocationIntoPosition(location: oldValue)
                }
            }
        }
        .coordinateSpace(name: "POSITIONALPAD")
        .onAppear {
            guard rows.isEmpty else { return }
            setupRows()
        }
        .onChange(of: position) { _, _ in
            if !isDragging {
                setupRows()
            }
        }
    }

    private func setupRows() {
        let cappedPosition = CGPoint(
            x: max(0, min(1, position.x)),
            y: max(0, min(1, position.y)),
        )
        let location = translateLocationIntoLocation(location: cappedPosition)
        updateActiveRowColumn(location: location)
        updateTouchPointOffset(location: location)
        createAndUpdateRows(location: location, isDragging: false)
    }

    private func createAndUpdateRows(location: CGPoint, isDragging: Bool) {
        if rows.isEmpty {
            for row in 0 ..< config.count {
                var columns: [Column] = []
                for column in 0 ..< config.count {
                    columns.append(.init(column: column, scale: 0, opacity: 0))
                }
                rows.append(.init(row: row, columns: columns))
            }
        }

        // Tip: proximity-driven falloff is the core visual.
        // For each cell:
        //   1. distance = Euclidean distance from cell to touch point.
        //   2. proximity = 1 - clamp(distance / influencesRadius, 0...1)
        //      → 1 at the touch point, 0 beyond `influencesRadius`.
        //   3. Linear lerps map proximity into scale (0.7 → 1.7) and
        //      opacity (0.1 → 1.1, capped naturally by SwiftUI).
        //
        // Branching at the bottom:
        //   • While dragging, every cell uses the proximity values.
        //   • Idle state keeps row/column highlight: cells on the
        //     active row OR column are full opacity; everywhere else
        //     dims to 0.3. The exact (activeRow, activeColumn) cell
        //     scales up to `circleZoom` (3x) — the "current value" pip.
        for rowItem in rows {
            let row = rowItem.row
            for columnItem in rowItem.columns {
                let column = columnItem.column
                let xPos = CGFloat(column) * itemSize
                let yPos = CGFloat(row) * itemSize

                let dx: CGFloat = location.x - xPos
                let dy: CGFloat = yPos - location.y

                let distance: CGFloat = sqrt(dx * dx + dy * dy)
                let proximity = 1 - max(min(distance / config.influencesRadius, 1), 0)

                let scale: CGFloat = 0.7 + (proximity * 1)
                let opacity: CGFloat = 0.1 + (proximity * 1)

                let isActive = activeRow == row || activeColumn == column
                let isZoomed = activeRow == row && activeColumn == column

                rows[row].columns[column].scale = isDragging ? scale : (isZoomed ? circleZoom : 1)
                rows[row].columns[column].opacity = isDragging ? opacity : (isActive ? 1 : 0.3)
            }
        }
    }

    private func updateActiveRowColumn(location: CGPoint) {
        activeColumn = Int(location.x / itemSize)
        activeRow = Int(location.y / itemSize)
    }

    private func updateTouchPointOffset(location: CGPoint) {
        let snappedX = CGFloat(activeColumn) * itemSize
        let snappedY = CGFloat(activeRow) * itemSize
        let radius: CGFloat = isDragging ? (itemSize / 2) : 0

        touchPointOffset = .init(
            width: (isDragging ? location.x : snappedX) - radius,
            height: (isDragging ? location.y : snappedY) - radius
        )
    }

    /// Translate location into position [0-1] in x & y
    private func translateLocationIntoPosition(location: CGPoint) {
        let minValue = itemSize / 2
        let maxValue = config.size - itemSize / 2

        let x = (location.x - minValue) / (maxValue - minValue)
        let y = (location.y - minValue) / (maxValue - minValue)

        position = .init(
            x: max(0, min(1, x)),
            y: max(0, min(1, y))
        )
    }

    /// Translate location into Location [0-1] in x & y location value
    private func translateLocationIntoLocation(location _: CGPoint) -> CGPoint {
        let minValue = itemSize / 2
        let maxValue = config.size - itemSize / 2

        let clampedX = max(0, min(1, position.x))
        let clampedY = max(0, min(1, position.y))

        let x = minValue + clampedX * (maxValue - minValue)
        let y = minValue + clampedY * (maxValue - minValue)

        return CGPoint(x: x, y: y)
    }

    /// Position pad config
    struct Config {
        /// max count 20, 15 is extreme
        var count: Int = 11
        var size: CGFloat = 200
        var tint: Color = .white
        var circleSize: CGFloat = 6
        var touchPointSize: CGFloat = 40
        var influencesRadius: CGFloat = 60
    }

    /// circle info
    private struct Row: Identifiable {
        var id: String = UUID().uuidString
        var row: Int
        var columns: [Column]
    }

    private struct Column: Identifiable {
        var id: String = UUID().uuidString
        var column: Int
        var scale: CGFloat
        var opacity: CGFloat
    }

    private var itemSize: CGFloat {
        config.size / CGFloat(config.count)
    }

    private var circleZoom: CGFloat {
        3
    }
}

// swiftlint:enable identifier_name

#Preview {
    TwoDSliderTonePickerDemoView()
}
