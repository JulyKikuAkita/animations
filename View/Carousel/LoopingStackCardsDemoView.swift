//
//  LoopingStackCardsDemoView.swift
//  animation
//
//  Standalone demo (not wired into the app's demo browser; preview-only).
//  iOS 18+ only — `Group(subviews:)` is the gating API.
//
//  Learning point
//  ──────────────
//  Tinder-style stack of cards where the top card drags left to
//  reveal the next. On release, if the drag exceeded a threshold
//  the card animates off-screen and the stack rotates so the next
//  card becomes top; otherwise it springs back. Implemented via
//  iOS 18's `Group(subviews:)` so callers pass a normal `ForEach`
//  without IDs.
//
//  How the rotation works:
//    • `Group(subviews:)` exposes the children as a `SubviewsCollection`.
//    • A custom extension `rotateFromLeft(by:)` returns a copy with
//      the first N items moved to the end — cycling without
//      mutating state.
//    • State stores how many cards have been "consumed"; the view
//      rebuilds from `collection.rotateFromLeft(by: rotation)` so
//      the visible top card is always at index 0.
//
//  Drag mechanics:
//    • `DragGesture` updates `offset.width` directly while dragging.
//    • `.rotation3DEffect(.degrees(offset.width / 20), axis: (0,1,0))`
//      tilts the card around the Y-axis as it slides — that's the
//      "physical card peeling off" feel.
//    • On end: if `|offset.width| > threshold`, animate offset further
//      off-screen, then bump the rotation index inside
//      `.animation(...) { logicallyComplete(after: ...) }` so the
//      stack updates after the card has visually left.
//
//  Key APIs
//  ────────
//  • `Group(subviews: content) { collection in ... }` — iOS 18+
//    SubViews API.
//  • `SubviewsCollection.rotateFromLeft(by:)` — file-local extension;
//    handy little utility.
//  • `DragGesture` + `.rotation3DEffect` + `.offset` — standard
//    Tinder-card combo.
//  • `.animation(...) { logicallyComplete(after:) }` — defers a
//    state mutation until the visible animation finishes.
//
//  How to apply
//  ────────────
//  Reach for this for any "swipe to advance" stack — onboarding,
//  card-based pickers, mini deck shufflers. The threshold + tilt
//  numbers (`20`, the offset cutoff) are tuning knobs you'll want
//  to expose if you generalise this.
//
//  See also
//  ────────
//  • InfiniteCarouselView.swift — also uses `Group(subviews:)`,
//    different mechanic (auto-advancing horizontal pager).
//  • View/3DAnimation/* — for richer 3D card flip patterns.
//
import SwiftUI

struct LoopingStackCardsDemoView: View {
    var body: some View {
        NavigationStack {
            VStack {
                GeometryReader {
                    let width = $0.size.width
                    VStack {
                        LoopingStack(maxTranslationWidth: width) {
                            ForEach(playItems) { image in
                                Image(image.image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 100, height: 100)
                                    .clipShape(.circle)
                                    .padding(5)
                                    .background {
                                        Circle()
                                            .fill(.background)
                                    }
                            }
                        }

                        LoopingStack(maxTranslationWidth: width) {
                            ForEach(firstSetCards) { image in
                                Image(image.image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 250, height: 400)
                                    .clipShape(.rect(cornerRadius: 30))
                                    .padding(5)
                                    .background {
                                        RoundedRectangle(cornerRadius: 35)
                                            .fill(.background)
                                    }
                                    .padding(.bottom, 10)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
//                .frame(height: 120)
            }
            .navigationTitle("Looping Stack")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.gray.opacity(0.2))
        }
    }
}

/// Starting iOS18 we can extract subview Collection from a view content with the help of Group
struct LoopingStack<Content: View>: View {
    var visibleCardsCount: Int = 2
    var maxTranslationWidth: CGFloat?
    @ViewBuilder var content: Content
    /// View Properties
    @State private var rotation: Int = 0
    var body: some View {
        Group(subviews: content) { collection in
            let collection = collection.rotateFromLeft(by: rotation)
            let count = collection.count

            ZStack {
                ForEach(collection) { view in
                    /// reverse the view stack with zIndex
                    let index = collection.index(view)
                    let zIndex = Double(count - index)

                    LoopingStackCardView(
                        index: index,
                        count: count,
                        visibleCardsCount: visibleCardsCount,
                        maxTranslationWidth: maxTranslationWidth,
                        rotation: $rotation
                    ) {
                        view
                    }
                    .zIndex(zIndex)
                }
            }
        }
    }
}

/// Card detail view
struct LoopingStackCardView<Content: View>: View {
    var index: Int
    var count: Int
    var visibleCardsCount: Int
    var maxTranslationWidth: CGFloat?

    @Binding var rotation: Int
    @ViewBuilder var content: Content
    /// Interaction Properties
    @State private var offset: CGFloat = .zero
    /// calculate the end result when drag is ended (push to the next card)
    @State private var viewSize: CGSize = .zero
    var body: some View {
        let extraOffset = min(CGFloat(index) * 20, CGFloat(visibleCardsCount) * 20)
        let scale = 1 - min(CGFloat(index) * 0.07, CGFloat(visibleCardsCount) * 0.07)
        let rotationDegree: CGFloat = -30
        let rotation = max(min(-offset / viewSize.width, 1), 0) * rotationDegree

        content
            .onGeometryChange(for: CGSize.self, of: {
                $0.size
            }, action: {
                viewSize = $0
            })
            .offset(x: extraOffset)
            .scaleEffect(scale, anchor: .trailing)
            .animation(.smooth(duration: 0.25, extraBounce: 0), value: index)
            .offset(x: offset)
            .rotation3DEffect(.init(degrees: rotation), axis: (0, 1, 0), anchor: .center, perspective: 0.5)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let xOffset = -max(-value.translation.width, 0)
                        if let maxTranslationWidth {
                            let progress = -max(min(-xOffset / maxTranslationWidth, 1), 0) * viewSize.width
                            offset = progress
                        } else {
                            offset = xOffset
                        }
                    }.onEnded { value in
                        let xVelocity = max(-value.velocity.width / 5, 0)
                        if (-offset + xVelocity) > (viewSize.width * 0.65) {
                            /// push to the next card
                            pushToNextCard()
                        } else {
                            withAnimation(.smooth(duration: 0.3, extraBounce: 0)) {
                                offset = .zero
                            }
                        }
                    },
                /// enable gesture on the first card
                isEnabled: index == 0 && count > 1
            )
    }

    /// 1. shift the card to it's view's width
    /// 2. apply rotation effect: update zIndex and reset offset to 0
    private func pushToNextCard() {
        withAnimation(.smooth(duration: 0.25, extraBounce: 0).logicallyComplete(after: 0.15),
                      completionCriteria: .logicallyComplete)
        {
            offset = -viewSize.width /// step 1
        } completion: {
            rotation += 1
            withAnimation(.smooth(duration: 0.25, extraBounce: 0)) {
                offset = .zero /// step 2
            }
        }
    }
}

extension SubviewsCollection {
    /// e.g., given array = [1, 2, 3, 4, 5], rotate by 2 steps
    /// the result is [3, 4, 5, 1, 2]
    func rotateFromLeft(by amount: Int) -> [SubviewsCollection.Element] {
        guard !isEmpty else { return [] }
        let moveIndex = amount % count
        let rotatedElements = Array(self[moveIndex...]) + Array(self[0 ..< moveIndex])
        return rotatedElements
    }
}

extension [SubviewsCollection.Element] {
    func index(_ item: SubviewsCollection.Element) -> Int {
        firstIndex(where: { $0.id == item.id }) ?? 0
    }
}

#Preview {
    LoopingStackCardsDemoView()
}
