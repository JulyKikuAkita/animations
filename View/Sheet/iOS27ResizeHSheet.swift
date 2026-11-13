//
//  iOS27ResizeHSheet.swift
//  animation
//
//  Created on 11/13/26.
//
//  Learning points / Demo goals:
//  • A sheet whose height follows a horizontal pager: each page has its own
//    detent fraction, and while swiping the sheet resizes continuously between
//    neighbouring pages instead of jumping when the page snaps.
//  • Paging: `containerRelativeFrame(.horizontal)` makes each page one sheet
//    wide and `scrollTargetBehavior(.paging)` snaps to it.
//  • Progress: `onScrollGeometryChange` turns the offset into a page index
//    (`(contentOffset.x + contentInsets.leading) / containerSize.width`), so
//    1.5 means halfway between page 2 and page 3.
//  • `interpolated(progress:)` lerps between the two neighbouring detents and
//    clamps at both ends, so rubber-band overscroll can't push the sheet past
//    the first or last detent.
//  • Only one detent is ever offered: `presentationDetents([.fraction(x)])`
//    with a changing `x` resizes the sheet live, with no `selection` binding.
//  • A custom `@resultBuilder` (`buildPartialBlock`) only accepts
//    `ScrollSheetContent` children, so every page is guaranteed to be wrapped
//    in the full-width frame at compile time.
//  • Each button fills 90% of the sheet (`containerRelativeFrame` on both
//    axes + a label framed to `.infinity`), so the resize is visible as the
//    button stretching and shrinking mid-swipe.
//  • Programmatic paging: `ScrollPosition.scrollTo(id:)` inside `withAnimation`
//    drives the same scroll-geometry path, so the sheet resizes for button taps
//    too.
//
//  Takeaway:
//    Derive the presentation state from scroll geometry instead of storing it
//    separately. One source of truth (the offset) drives both the pager and the
//    sheet height, so swipes and button taps can't drift out of sync.

import SwiftUI

struct ResizeHScrollSheetDemo: View {
    @State private var showSheet: Bool = false
    @State private var scrollPosition: ScrollPosition = .init()
    var body: some View {
        NavigationStack {
            List {
                Button("Show Sheet") {
                    showSheet.toggle()
                }
            }
            .navigationTitle("Resizable Scroll Sheet")
        }
        .sheet(isPresented: $showSheet) {
            ResizableScrollSheet(detentFractions: [0.25, 0.7, 0.35]) {
                ScrollSheetContent(tint: .blue) {
                    Button {
                        withAnimation(.snappy) {
                            scrollPosition.scrollTo(id: "2")
                        }
                    } label: {
                        Text("Page 2 →")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .id("1")
                }

                ScrollSheetContent(tint: .orange) {
                    Button {
                        withAnimation(.snappy) {
                            scrollPosition.scrollTo(id: "3")
                        }
                    } label: {
                        Text("Page 3 →")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .id("2")
                }

                ScrollSheetContent(tint: .green) {
                    Button {
                        withAnimation(.snappy) {
                            scrollPosition.scrollTo(id: "1")
                        }
                    } label: {
                        Text("Back to Start")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .id("3")
                }
            }
            .scrollPosition($scrollPosition)
        }
    }
}

private struct ScrollSheetContent<Content: View>: View {
    var tint: Color = .accentColor
    @ContentBuilder var content: Content
    var body: some View {
        content
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(tint)
            // 90% of the sheet in both axes, so the button visibly tracks the
            // live detent height; the outer frame keeps each page full width
            // for paging.
            .containerRelativeFrame([.horizontal, .vertical]) { length, _ in
                length * 0.9
            }
            .containerRelativeFrame(.horizontal)
    }
}

@resultBuilder
private struct ScrollSheetContentBuilder {
    static func buildPartialBlock<C>(
        first: ScrollSheetContent<C>
    ) -> ScrollSheetContent<C> {
        first
    }

    static func buildPartialBlock<A: View, C>(
        accumulated: A,
        next: ScrollSheetContent<C>
    ) -> TupleView<(A, ScrollSheetContent<C>)> {
        TupleView((accumulated, next))
    }
}

private struct ResizableScrollSheet<Content: View>: View {
    var detentFractions: [CGFloat]
    var content: Content
    init(
        detentFractions: [CGFloat],
        @ScrollSheetContentBuilder content: @escaping () -> Content
    ) {
        self.detentFractions = detentFractions
        self.content = content()
        // Fallback to mid-sheet
        currentDetentFraction = detentFractions.first ?? 0.5
    }

    /// View Properties
    @State private var currentDetentFraction: CGFloat
    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                content
            }
        }
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.hidden)
        .onScrollGeometryChange(for: CGFloat.self) {
            let offset = $0.contentOffset.x + $0.contentInsets.leading
            return offset / $0.containerSize.width
        } action: { _, newValue in
            guard !detentFractions.isEmpty else { return }
            currentDetentFraction = detentFractions.interpolated(progress: newValue)
        }
        .presentationDetents([.fraction(currentDetentFraction)])
    }
}

/// interpolating between detent values using progress
private extension [CGFloat] {
    func interpolated(progress: CGFloat) -> CGFloat {
        guard let first, let last else { return 0 }
        if progress <= 0 {
            return first
        }
        if progress >= CGFloat(count - 1) {
            return last
        }

        let index = Int(progress)
        let fraction = progress - CGFloat(index)

        let start = self[index]
        let end = self[index + 1]

        return start + (end - start) * fraction
    }
}

#Preview {
    ResizeHScrollSheetDemo()
}
