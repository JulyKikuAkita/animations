//
//  AnimatedPagingIndicatorsView.swift
//  animation
//
//  Standalone demo (not wired into the app's demo browser; preview-only).
//
//  Learning point
//  ──────────────
//  Paging carousel where the page-control dots animate as the user
//  swipes — instead of the active dot hard-flipping on settle, dots
//  scale and slide continuously while the user drags. The trick is
//  using a single `progress` value (continuous 0...N) derived from
//  `onScrollGeometryChange` to drive both dot scale and the carousel's
//  active-page index.
//
//  Key APIs
//  ────────
//  • `.scrollTargetBehavior(.paging)` + `.scrollTargetLayout()` —
//    iOS 17+. Snap one full page per swipe.
//  • `.containerRelativeFrame(.horizontal)` — sizes each card to
//    match the carousel viewport.
//  • `onScrollGeometryChange(for: CGFloat.self)` reading
//    `contentOffset.x / pageWidth` — the continuous progress that
//    feeds dot interpolation.
//
//  How to apply
//  ────────────
//  Use when stock `.tabViewStyle(.page)` indicators feel too plain.
//  Style the dots however you like — the `progress`-driven scale
//  pattern is the reusable piece.
//
//  See also
//  ────────
//  • CardCarouselWithScrollTransitionsAPI.swift — alternative
//    approach using `.scrollTransition(.interactive)` on each card.
//
import SwiftUI

struct PagingIndicatorsDemoView: View {
    var body: some View {
        NavigationStack {
            AnimatedPagingIndicatorsView()
        }
    }
}

// 1:51
struct AnimatedPagingIndicatorsView: View {
    /// View Properties
    @State private var colors: [Color] = [.pink, .purple, .blue, .green]
    @State private var opacityEffect: Bool = false
    @State private var clipEdges: Bool = false
    var body: some View {
        VStack {
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(colors, id: \.self) { color in
                        RoundedRectangle(cornerRadius: 25)
                            .fill(color.gradient)
                            .padding(.horizontal, 5)
                            .containerRelativeFrame(.horizontal)
                    }
                }
                .overlay(alignment: .bottom) {
                    PageIndicatorView(
                        activeTint: .white,
                        inactiveTint: .black.opacity(0.25),
                        opacityEffect: opacityEffect,
                        clipEdges: clipEdges
                    )
                }
            }
            .scrollTargetBehavior(.paging) // comment this out for carousel style
            .scrollIndicators(.hidden)
            .frame(height: 220)
            .padding(15) // comment this out for carousel style
//            .scrollTargetBehavior(.viewAligned) /// use for carousel style
//            .safeAreaPadding(.vertical, 15)
//            .safeAreaPadding(.horizontal, 25)

            List {
                Section("Options") {
                    Toggle("Opacity Effect", isOn: $opacityEffect)
                    Toggle("Clip Edges", isOn: $clipEdges)

                    Button("Add Card") {
                        colors.append(.brown)
                    }
                }
            }
            .clipShape(.rect(cornerRadius: 15))
            .padding(15)
        }
        .navigationTitle("Custom Indicator")
    }
}

#Preview {
    PagingIndicatorsDemoView()
}
