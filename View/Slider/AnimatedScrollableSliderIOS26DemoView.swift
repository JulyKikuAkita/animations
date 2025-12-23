//
//  AnimatedScrollableSliderIOS26DemoView.swift
//  animation
//
//  Created on 12/22/25.
// if use scrollPosition to calculate the ticker,
// we won't be able to animate value as when scroll quickly,
// the value updated directly from one value to another.
// Thus we need to manually calculate the range to animate the ticks

import SwiftUI

struct AnimatedScrollableSliderIOS26DemoView: View {
    @State private var selection: Int = 0

    var body: some View {
        NavigationStack {
            VStack {
                TickPicker(count: 100, config: config, selection: $selection)

                Text("\(selection)")
                    .monospaced()
                    .fontWeight(.medium)

                Button("Update tick to center") {
                    selection = 50
                }
            }
            .navigationTitle("Tick Picker")
        }
    }

    var config: TickConfig {
        .init(tickWidth: 2,
              alignment: .center)
    }
}

struct TickPicker: View {
    var count: Int
    var config: TickConfig = .init()
    @Binding var selection: Int

    /// View Properties
    @State private var scrollIndex: Int = 0
    @State private var scrollPosition: Int?
    @State private var scrollPhase: ScrollPhase = .idle
    @State private var animationRange: ClosedRange<Int> = 0 ... 0
    @State private var completeInitialSetup: Bool = false
    var body: some View {
        GeometryReader {
            let size = $0.size

            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(0 ... count, id: \.self) { index in
                        tickView(index)
                    }
                }
                .frame(height: config.tickHeight)
                .frame(maxHeight: .infinity)
                .contentShape(.rect)
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned(limitBehavior: .alwaysByOne))
            .scrollPosition(id: $scrollPosition, anchor: .center)
            /// centering tick start/end point
            .safeAreaPadding(.horizontal, (size.width - width) / 2)
            .onScrollGeometryChange(for: CGFloat.self) {
                $0.contentOffset.x + $0.contentInsets.leading
            } action: { _, newValue in
                guard scrollPhase != .idle else { return }
                let index = max(min(Int((newValue / width).rounded()), count), 0)
                let previousScrollIndex = scrollIndex
                scrollIndex = index

                let isGreater = scrollIndex > previousScrollIndex
                let leadingBound = isGreater ? previousScrollIndex : scrollIndex
                let trailingBound = !isGreater ? previousScrollIndex : scrollIndex

                animationRange = leadingBound ... trailingBound
            }
            .onScrollPhaseChange { _, newPhase in
                scrollPhase = newPhase
                // avoid animation staggering when rapid update on tick
                animationRange = scrollIndex ... scrollIndex

                /// Fix edge cases when view aligned target will not center the tick
                if newPhase == .idle, scrollPosition != scrollIndex {
                    withAnimation(config.animation) {
                        scrollPosition = scrollIndex
                    }
                }
            }
        }
        .frame(height: config.interactionHeight)
        .task {
            guard !completeInitialSetup else { return }

            /// Setup initial scroll
            updateScrollPosition(selection: selection)

            completeInitialSetup = true
        }
        .allowsHitTesting(completeInitialSetup)
        .onChange(of: scrollIndex) { _, newValue in
            Task {
                selection = newValue
            }
        }
        .onChange(of: selection) { _, newValue in
            guard scrollIndex != newValue else { return }
            updateScrollPosition(selection: newValue)
        }
    }

    @ViewBuilder
    func tickView(_ index: Int) -> some View {
        let height = config.tickHeight
        let isInside = animationRange.contains(index)
        let fillColor = scrollIndex == index ? config.activeTint : config.inactiveTint.opacity(isInside ? 1 : 0.4)
        Rectangle()
            .fill(fillColor)
            .frame(
                width: config.tickWidth,
                height: height * (isInside ? 1 : config.inActiveHeightProgress)
            )
            .frame(width: width, height: height, alignment: config.alignment.value)
            .clipped()
            .animation(isInside || completeInitialSetup ? .none : config.animation, value: isInside)
    }

    func updateScrollPosition(selection: Int) {
        let safeSelection = max(min(selection, count), 0)
        scrollPosition = safeSelection
        scrollIndex = safeSelection
        animationRange = safeSelection ... safeSelection
    }

    var width: CGFloat {
        config.tickWidth + (config.tickHPadding * 2)
    }
}

struct TickConfig {
    var tickWidth: CGFloat = 3
    var tickHeight: CGFloat = 30
    var tickHPadding: CGFloat = 3
    var inActiveHeightProgress: CGFloat = 0.55
    var interactionHeight: CGFloat = 60
    var activeTint: Color = .yellow
    var inactiveTint: Color = .primary
    var alignment: Alignment = .bottom
    var animation: Animation = .interpolatingSpring(duration: 0.3, bounce: 0, initialVelocity: 0)

    enum Alignment: String, CaseIterable {
        case top = "TOP"
        case bottom = "Bottom"
        case center = "Center"

        var value: SwiftUI.Alignment {
            switch self {
            case .top: .top
            case .bottom: .bottom
            case .center: .center
            }
        }
    }
}

#Preview {
    AnimatedScrollableSliderIOS26DemoView()
}
