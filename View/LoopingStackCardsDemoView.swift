//
//  LoopingStackCardsDemoView.swift
//  animation


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
                        rotation: $rotation) {
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
            completionCriteria: .logicallyComplete) {
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
    func rotateFromLeft(by: Int) -> [SubviewsCollection.Element] {
        guard !isEmpty else { return [] }
        let moveIndex = by % count
        let rotatedElements = Array(self[moveIndex...]) + Array(self[0..<moveIndex])
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
