//
//  LoopingStackCardsDemoView.swift
//  animation


import SwiftUI
struct LoopingStackCardsDemoView: View {
    var body: some View {
        NavigationStack {
            VStack {
                LoopingStack {
                    ForEach(playItems) { image in
                        Image(image.image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 200, height: 400)
                            .clipShape(.rect(cornerRadius: 30))
                            .padding(5)
                            .background {
                                RoundedRectangle(cornerRadius: 35)
                                    .fill(.background)
                            }
                    }
                }
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
    @ViewBuilder var content: Content
    /// Interaction Properties
    @State private var offset: CGFloat = .zero
    var body: some View {
        Group(subviews: content) { collection in
            let count = collection.count
            ZStack {
                ForEach(collection) { view in
                    /// reverse the view stack with zIndex
                    let index = collection.index(view)
                    let zIndex = Double(count - index)
                    /// Visible Card properties
                    let extraOffset = min(CGFloat(index) * 20, CGFloat(visibleCardsCount) * 20)
                    let scale = 1 - min(CGFloat(index) * 0.07, CGFloat(visibleCardsCount) * 0.07)
                    
                    LoopingStackCardView(
                        index: index,
                        count: count,
                        visibleCardsCount: visibleCardsCount) {
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
    @ViewBuilder var content: Content
    /// Interaction Properties
    @State private var offset: CGFloat = .zero
    /// calculate the end result when drag is ended (push to the next card)
    @State private var viewSize: CGSize = .zero
    var body: some View {
        let extraOffset = min(CGFloat(index) * 20, CGFloat(visibleCardsCount) * 20)
        let scale = 1 - min(CGFloat(index) * 0.07, CGFloat(visibleCardsCount) * 0.07)

        content
            .onGeometryChange(for: CGSize.self, of: {
                $0.size
            }, action: {
                viewSize = $0
            })
            .offset(x: extraOffset)
            .scaleEffect(scale, anchor: .trailing)
            .offset(x: offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let xOffset = -max(-value.translation.width, 0)
                        offset = xOffset
                    }.onEnded { value in
                        let xVelocity = max(-value.velocity.width / 5, 0)
                        if (-offset + xVelocity) > (viewSize.width * 0.65) {
                            /// push to the next card
                            
                        } else {
                            withAnimation(.smooth(duration: 0.3, extraBounce: 0)) {
                                offset = .zero
                            }
                        }
                    },
                /// enable gesture on the first card
                isEnabled: index == 0
            )
    }
}

extension SubviewsCollection {
    func index(_ item: SubviewsCollection.Element) -> Int {
        firstIndex(where: { $0.id == item.id }) ?? 0
    }
}

#Preview {
    LoopingStackCardsDemoView()
}
