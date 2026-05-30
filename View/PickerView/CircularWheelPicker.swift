//
//  CircularWheelPicker.swift
//  animation
//
//  Created on 8/11/25.
//  Standalone demo (not wired into the app's demo browser; preview-only).
//
//  ⚠️  KNOWN BROKEN ON iOS 26
//  ──────────────────────────
//  Symptom: scrolling updates `selectedValue` (the numeric label
//  above the wheel changes) but the wheel itself is visually inert
//  — ticks don't rotate or shift along the arc. Works as designed
//  on iOS 17 / 18.
//
//  Possible causes (none confirmed; tried and failed to fix —
//  tracking here so the next person doesn't re-walk the same
//  ground):
//    • iOS 26 may not re-invoke per-cell `GeometryReader` /
//      `.visualEffect` closures for transforms during scroll.
//      Replacing GR with `.visualEffect` (the iOS 17+ canonical
//      pattern) didn't help.
//    • `.scrollPosition(id:)` + `.scrollClipDisabled(true)` +
//      `.clipShape(...)` combo may produce stale scroll-space
//      coordinates in `proxy.frame(in: .scrollView(axis:))`.
//      Switching to a named coordinate space didn't help.
//    • `LazyHStack` may aggressively skip geometry updates for
//      cells visually outside the clip in iOS 26. Swapping to
//      plain `HStack` didn't help.
//    • The existing `.onScrollPhaseChange { activePosition = nil ... }`
//      kick may interact differently with iOS 26's scroll state
//      machine. Removing the kick didn't help.
//
//  Recommended fix path (not yet applied): bypass per-cell geometry
//  entirely — publish a single `scrollOffsetX` `@State` via
//  `.onScrollGeometryChange` on the parent ScrollView, then compute
//  each tick's rotation arithmetically from `(tickIndex,
//  scrollOffsetX, tickStride, viewWidth)` in plain view body.
//  `.onScrollGeometryChange` is confirmed to fire on iOS 26
//  elsewhere in this repo
//  (View/Carousel/AppleTVCarousel+iOS26.swift,
//  View/PhotosView/CarouselImageWithAmbientBackgroundEffectView.swift).
//
//  Learning point
//  ──────────────
//  Speedometer-style semicircular wheel picker: the user drags a
//  curve of tick marks across the bottom of the screen, the active
//  tick stays parked over a centre indicator, and a label above
//  shows the current value (5–100). The trick is that the underlying
//  scroll layout is a flat horizontal row of ticks — the bend
//  (each tick rotated by its angular position on the arc) is
//  applied via `rotationEffect` per tick, so SwiftUI's scroll
//  machinery handles all the inertia/snap for free.
//
//  Bend math
//  ─────────
//  For each tick at index `i` of N total in a half-circle:
//    • angle = (CGFloat(i) / CGFloat(N - 1)) × 180° − 90°
//    • Apply `.rotationEffect(.degrees(angle))` so the tick points
//      radially outward from the arc's centre.
//
//  Snap-to-position pattern
//  ────────────────────────
//  `scrollPosition(id:)` two-way binds to `activePosition`. After
//  the user lifts their finger and the scroll animation settles
//  (`.onScrollPhaseChange { phase = .idle }`), we read back the
//  current id and update the label. Reading on every tick (not
//  just settle) feels chatty and triggers redundant haptics — wait
//  for `.idle`.
//
//  Key APIs
//  ────────
//  • `.scrollPosition(id:)` + `.scrollTargetBehavior(.viewAligned(limitBehavior:))`
//    — paged snap with the active item's id exposed as a Binding.
//  • `.onScrollPhaseChange` — settle detection.
//  • Custom `Path { path.addArc(...) }` for the visual arc that
//    decorates the ticks.
//  • Per-tick `.rotationEffect(.degrees(...))` driven by index —
//    the bend illusion.
//
//  How to apply
//  ────────────
//  Use whenever a numeric range needs more visceral feedback than
//  a `Slider` (volume, exposure compensation, brightness). The
//  arc-based layout reads as more "physical" than a flat scroll.
//
//  See also
//  ────────
//  • ExpandableWheelPickerView.swift — sibling with overlay-mode +
//    radial layout; pick by interaction style (always-visible vs.
//    expand-on-tap).
//  • TimePickerView.swift — different kind of wheel (column-style
//    `Picker(.wheel)`) for hours/minutes/seconds.
//
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
    @State private var activePosition: Int?
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
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
            guard activePosition == nil else { return }
            activePosition = selectedValue
        }
        .onChange(of: activePosition) { _, newValue in
            if let newValue, selectedValue != newValue {
                selectedValue = newValue
            }
        }
        .onChange(of: selectedValue) { _, newValue in
            if activePosition != newValue {
                activePosition = newValue
            }
        }
        /// resolve a bug on scroll position not reset to the current position when scroll ends
        .onScrollPhaseChange { _, newPhase in
            if newPhase == .idle {
                Task {
                    activePosition = nil
                    try? await Task.sleep(for: .seconds(0))
                    activePosition = selectedValue
                }
            }
        }
    }

    /// Converting Range into Int Array
    var ticks: [Int] {
        stride(from: range.lowerBound, through: range.upperBound, by: 1).compactMap(\.self)
    }

    func wheelPickerScrollView(size: CGSize, radius: CGFloat) -> some View {
        /// Set clip shape to the wheelShape to limit interaction within the shape area
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
        .scrollPosition(id: $activePosition, anchor: .center)
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
            if let activePosition {
                label(activePosition)
                    .frame(maxWidth: radius,
                           maxHeight: radius - (config.strokeStyle.lineWidth / 2))
            }
        }
    }

    func tickView(_ value: Int, size: CGSize, radius: CGFloat) -> some View {
        let strokeWidth = config.strokeStyle.lineWidth
        let halfStrokeWidth = strokeWidth / 2
        let isLargerTick = (ticks.firstIndex(of: value) ?? 0) % config.largeTickFrequency == 0

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
        .frame(width: 3, height: isLargerTick ? (strokeWidth - 10) : halfStrokeWidth)
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
    CircularWheelPickerDemoView()
}
