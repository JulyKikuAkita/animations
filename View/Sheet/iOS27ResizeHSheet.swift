//
//  iOS27ResizeHSheet.swift
//  animation
//
//  Created on 11/13/26.

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
                ScrollSheetContent {
                    Button("Next") {
                        withAnimation(.snappy) {
                            scrollPosition.scrollTo(id: "2")
                        }
                    }
                    .id("1")
                }

                ScrollSheetContent {
                    Button("Next") {
                        withAnimation(.snappy) {
                            scrollPosition.scrollTo(id: "3")
                        }
                    }
                    .id("2")
                }

                ScrollSheetContent {
                    Button("Next") {
                        withAnimation(.snappy) {
                            scrollPosition.scrollTo(id: "1")
                        }
                    }
                    .id("3")
                }
            }
            .scrollPosition($scrollPosition)
        }
    }
}

private struct ScrollSheetContent<Content: View>: View {
    @ContentBuilder var content: Content
    var body: some View {
        content
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
