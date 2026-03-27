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

struct PhotosStylePositionPad: View {
    var config: Config = .init()
    @Binding var position: CGPoint
    /// View Properties
    @State private var rows: [Row] = []
    var body: some View {
        VStack(spacing: 0) {
            ForEach(rows) { row in
                HStack(spacing: 0) {
                    ForEach(row.columns) { _ in
                        Circle()
                            .fill(config.tint)
                            .frame(width: config.circleSize, height: config.circleSize)
                            .frame(width: itemSize, height: itemSize)
                    }
                }
            }
        }
        .frame(width: config.size, height: config.size)
        .onAppear {
            guard rows.isEmpty else { return }
            createAndUpdateRows(location: .zero, isDragging: false)
        }
    }

    private func createAndUpdateRows(location _: CGPoint, isDragging _: Bool) {
        if rows.isEmpty {
            for row in 0 ..< config.count {
                var columns: [Column] = []
                for column in 0 ..< config.count {
                    columns.append(.init(column: column, scale: 0, opacity: 0))
                }
                rows.append(.init(row: row, columns: columns))
            }
        }
    }

    /// Position pad config
    struct Config {
        /// max count 20, 15 is extreme
        var count: Int = 11
        var size: CGFloat = 200
        var tint: Color = .white
        var circleSize: CGFloat = 6
        var touchPointSize: CGFloat = 40
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
}

#Preview {
    TwoDSliderTonePickerDemoView()
}
