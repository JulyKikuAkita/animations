//
//  CircularWheelPicker.swift
//  animation
//
//  Created on 8/11/25.
// iOS 26

import SwiftUI

struct CircularWheelPickerDemoView: View {
    @State private var selectedValue: Int = 50
    var body: some View {
        NavigationStack {
            VStack {
                Text("Value: \(selectedValue)")
                    .onTapGesture {
                        selectedValue = 77
                    }
                Spacer(minLength: 0)

                WheelPickerView(
                    range: 5 ... 100,
                    selectedValue: $selectedValue
                ) { currentValue in
                    Text(String(currentValue))
                        .font(.title)
                        .fontWeight(.semibold)
                        .contentTransition(.numericText())
                        .animation(.snappy, value: currentValue)
                }
            }
        }
    }
}

struct WheelPickerView<Label: View>: View {
    var range: ClosedRange<Int>
    @Binding var selectedValue: Int
    var config: WheelPickerConfig = .init()
    @ViewBuilder var label: (Int) -> Label

    /// View Properties
    @State private var activePosoition: Int?
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            /// Removing line-width from the width
            let width = size.width - (config.strokeStyle.lineWidth)
            let diameter = min(max(size.width, size.height), size.width)
            let radius: CGFloat = diameter / 2

            wheelPath(size, radius: radius)
                .stroke(config.strokeColor, style: config.strokeStyle)
                .overlay {
                    wheelPickerScrollView(size: size, radius: radius)
                }
                /// Removing line width from the height with offset
                .offset(y: -config.strokeStyle.lineWidth / 2)
        }
        .frame(height: config.height)
        .task {
            guard activePosoition == nil else { return }
            activePosoition = selectedValue
        }
        .onChange(of: activePosoition) { _, newValue in
            if let newValue, selectedValue != newValue {
                selectedValue = newValue
            }
        }
        .onChange(of: selectedValue) { _, newValue in
            if activePosoition != newValue {
                activePosoition = newValue
            }
        }
        /// resolve a bug on scroll position not reest to the current position when scroll ends
        .onScrollPhaseChange { _, newPhase in
            if newPhase == .idle {
                Task {
                    activePosoition = nil
                    try? await Task.sleep(for: .seconds(0))
                    activePosoition = selectedValue
                }
            }
        }
    }

    /// Converting Range into Int Array
    var ticks: [Int] {
        stride(from: range.lowerBound, through: range.upperBound, by: 1).compactMap(\.self)
    }

    func wheelPickerScrollView(size: CGSize, radius: CGFloat) -> some View {
        /// Set clipshape to the wheelShape to limit interaction within the shape area
        let wheelShape = wheelPath(size, radius: radius)
            .strokedPath(config.strokeStyle)

        return ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(ticks, id: \.self) { tick in
                    tickView(tick, size: size, radius: radius)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                }
            }
            .scrollTargetLayout()
        }
        .scrollIndicators(.hidden)
        .scrollClipDisabled(true)
        /// position picker start/end at the center
        .safeAreaPadding(.horizontal, (size.width - 8) / 2)
        .scrollTargetBehavior(.viewAligned(limitBehavior: .alwaysByOne))
        .scrollPosition(id: $activePosoition, anchor: .center)
        .clipShape(wheelShape)
        .contentShape(wheelShape) /// optional to limit interaction area
        /// mark and label view
        .overlay(alignment: .bottom) {
            let strokeWidth = config.strokeStyle.lineWidth
            let halfStrokeWidth = strokeWidth / 2

            VStack(spacing: -5) {
                Capsule()
                    .fill(config.activeTint)
                    .frame(width: 5, height: strokeWidth)

                Circle()
                    .fill(config.activeTint)
                    .frame(width: 10, height: 10)
            }
            .offset(y: -radius + halfStrokeWidth)
        }
        .overlay(alignment: .bottom) {
            if let activePosoition {
                label(activePosoition)
                    .frame(maxWidth: radius,
                           maxHeight: radius - (config.strokeStyle.lineWidth / 2))
            }
        }
    }

    func tickView(_ value: Int, size: CGSize, radius: CGFloat) -> some View {
        let strokeWidth = config.strokeStyle.lineWidth
        let halfStrokeWidth = strokeWidth / 2
        let isLargetTick = (ticks.firstIndex(of: value) ?? 0) % config.largeTickFrequency == 0

        return GeometryReader { proxy in
            /// rotate the tick to match the stroke border shape
            let minX = proxy.frame(in: .scrollView(axis: .horizontal)).minX
            let midX = proxy.frame(in: .scrollView(axis: .horizontal)).midX
            let halfWidth = size.width / 2
            /// left-right
            let progress = max(min(midX / halfWidth, 1), -1)
            /// -180...180
            let rotation = Angle(degrees: progress * 180)
            Capsule()
                .fill(config.inactiveTint)
                .offset(y: -radius + halfWidth)
                .rotationEffect(rotation, anchor: .bottom)
                .offset(x: -minX)
        }
        .frame(width: 3, height: isLargetTick ? (strokeWidth - 10) : halfStrokeWidth)
        .frame(width: 8, alignment: .leading)
    }

    func wheelPath(_ size: CGSize, radius: CGFloat) -> Path {
        Path { path in
            path
                .addArc(
                    /// Bottom Center
                    center: .init(x: size.width / 2, y: size.height),
                    radius: radius,
                    startAngle: .degrees(180),
                    endAngle: .degrees(0),
                    clockwise: false
                )
        }
    }

    struct WheelPickerConfig {
        var activeTint: Color = .primary
        var inactiveTint: Color = .gray
        var largeTickFrequency: Int = 10
        var strokeStyle: StrokeStyle = .init(
            lineWidth: 50,
            lineCap: .round,
            lineJoin: .round
        )
        var strokeColor: Color = .black.opacity(0.1)
        var height: CGFloat = 200
    }
}

#Preview {
    circularWheelPickerDemoView()
}
