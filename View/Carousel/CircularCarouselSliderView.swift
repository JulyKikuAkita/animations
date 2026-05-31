//
//  CircularCarouselSliderView.swift
//  animation
//
//  Created by IFang Lee on 4/4/24.
//
//  Standalone demo (not wired into the app's demo browser; preview-only).
//
//  Learning point
//  ──────────────
//  Vertical slider where cards "bob" up and down as they pass the
//  centre — the cards trace an arc rather than a straight line. Two
//  modes (`Normal` / `Scaled`) toggle the same trick on/off so you
//  can see the carousel's underlying linear scroll versus the arced
//  presentation.
//
//  How the arc is faked: each card's `visualEffect` reads its position
//  in scroll-space, normalises it to a 0...1 progress relative to the
//  viewport centre, and applies an `offset(x:)` whose magnitude grows
//  toward the edges. The cards themselves never move along an actual
//  curve — `visualEffect` translates them sideways at render time so
//  layout/hit-testing stays linear.
//
//  Key APIs
//  ────────
//  • `.visualEffect { content, proxy in ... }` — iOS 17+. The hook
//    where the per-card progress→offset math lives.
//  • `.scrollTransition(.interactive)` — phase-driven scale for the
//    `Scaled` mode.
//  • `.scrollPosition(id:)` + `.scrollTargetBehavior(.viewAligned)` —
//    paged snap with a binding for selection.
//  • `safeAreaPadding(.vertical, ...)` — half-viewport padding so the
//    first/last item can rest at centre.
//
//  How to apply
//  ────────────
//  Use when you want a vertical date / number / option picker that
//  feels more "physical" than a flat list. The progress→offset
//  function is the customisable knob — swap in your own curve
//  (`sin`, `pow`, etc.) for a different arc shape.
//
//  See also
//  ────────
//  • VerticalCircularCarouselView.swift — same vertical layout but
//    uses `rotation3DEffect` around the leading edge instead of a
//    sideways `offset`. Compare and contrast.
//  • CircularCarousel18View (in CardCarouselWithScrollTransitionsAPI.swift)
//    — iOS 18 `.scrollTransition`-based version of a similar idea.
//
import SwiftUI

struct CircularCarouselSliderView: View {
    /// View properties
    @State private var pickerType: TripPicker = .normal
    @State var cards: [Card] = firstSetCards
    @State private var activeID: String? /// ios 17 api to track scroll view position
    var body: some View {
        VStack {
            Picker("", selection: $pickerType) {
                ForEach(TripPicker.allCases, id: \.rawValue) {
                    Text($0.rawValue)
                        .tag($0)
                }
            }
            .pickerStyle(.segmented)
//            .padding()

//            Spacer(minLength: 0)

            GeometryReader {
                let size = $0.size
                let padding = (size.width - 70) / 2

                /// Circular Slider
                ScrollView(.horizontal) {
                    HStack(spacing: 35) {
                        ForEach(cards, id: \.image) { card in
                            Image(card.image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 70, height: 70)
                                .clipShape(.circle)
                                /// Shadow
                                .shadow(color: .black.opacity(0.15), radius: 5, x: 5, y: 5)
                                .visualEffect { view, proxy in
                                    view
                                        .offset(y: offSet(proxy))
                                        .offset(y: scale(proxy) * 15) /// use scroll progress to achieve circular slider
                                } /// iOS 17 api to achieve circular slider (or use scroll progress)
                                .scrollTransition(.interactive, axis: .horizontal) { view, phase in
                                    view
//                                    .offset(y: phase.isIdentity && activeID == card.image ? 15 : 0)
                                        .scaleEffect(phase.isIdentity &&
                                            activeID == card.image &&
                                            pickerType == .scaled ? 1.5 : 1, anchor: .bottom)
                                    // use activeID to enlarge the center image
                                }
                        }
                    }
                    .frame(height: size.height)
                    .offset(y: -30)
//                    .padding(.horizontal, padding)  // comparing padding vs safeAreaPadding
                    .scrollTargetLayout()
                }
                .background(content: {
                    if pickerType == .normal {
                        Circle()
                            .fill(.white.shadow(.drop(color: .black.opacity(0.2), radius: 5)))
                            .frame(width: 85, height: 85)
                            .offset(y: -15)
                    }
                })
                .safeAreaPadding(.horizontal, padding)
                .scrollIndicators(.hidden)
                /// Snapping
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $activeID) /// ios 17 api to track scroll view posititon
                .frame(height: size.height)
            }
            .frame(height: 200)
//            .background(Color.green)
        }
        .ignoresSafeArea(.container, edges: .bottom)
    }

    /// Circular slider view offset
    nonisolated func offSet(_ proxy: GeometryProxy) -> CGFloat {
        let progress = progress(proxy)
        /// Simply moving view up/down based on progress
        return progress < 0 ? progress * -30 : progress * 30
    }

    nonisolated func scale(_ proxy: GeometryProxy) -> CGFloat {
        let progress = min(max(progress(proxy), -1), 1)
        return progress < 0 ? 1 + progress : 1 - progress
    }

    nonisolated func progress(_ proxy: GeometryProxy) -> CGFloat {
        /// View Width
        let viewWidth = proxy.size.width
        let minX = (proxy.bounds(of: .scrollView)?.minX ?? 0)
        return minX / viewWidth
    }
}

#Preview {
    CircularCarouselSliderView()
}

/// Slider Type
enum TripPicker: String, CaseIterable {
    case scaled = "Scaled"
    case normal = "Normal"
}
