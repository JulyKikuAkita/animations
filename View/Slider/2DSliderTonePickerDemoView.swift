//
//  2DSliderTonePickerDemoView.swift
//  animation
//
//  Created on 3/27/26.
// Photos App Tone Picker - 2S slider
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
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .named("POSITIONALPAD"))
                .updating($dragLocation) { value, out, _ in
                    let location = value.location

                    /// Capping location to match the itemSize
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

        /// Updating scale and opacity based on location with influence radius
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
