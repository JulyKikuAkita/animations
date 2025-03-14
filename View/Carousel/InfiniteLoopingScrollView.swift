//
//  InfiniteLoopingScrollView.swift
//  animation
// https://www.youtube.com/watch?v=lyuo59840qs&list=PLimqJDzPI-H97JcePxWNwBXJoGS-Ro3a-&index=56
import SwiftUI

struct InfiniteLoopingScrollDemoView: View {
    var body: some View {
        NavigationStack {
            InfiniteLoopingScrollView()
                .navigationTitle("Looping Scroll View")
        }
    }
}

struct InfiniteLoopingScrollView: View {
    @State private var items: [CreditCard] = creditCards
    var body: some View {
        ScrollView(.vertical) {
            VStack {
                GeometryReader {
                    let size = $0.size
                    LoopingScrollView(width: size.width, spacing: 0, items: items) { item in
                        let index = items.firstIndex(where: { $0.id == item.id }) ?? -100
                        RoundedRectangle(cornerRadius: 15)
                            .fill(item.color.gradient)
                            .padding(.horizontal, 15)
                            .overlay {
                                Text("\(index + 1)")
                                    .font(.largeTitle)
                                    .foregroundStyle(.gray)
                            }
                    }
//                    .contentMargins(.horizontal, 15, for: .scrollContent) /// adding margin to scrollview w/o impacting it's natural bound
                    .scrollTargetBehavior(.paging)
                }
                .frame(height: 220)
            }
            .padding(.vertical, 15)
        }
        .scrollIndicators(.hidden)
    }
}

/// iOS 17: passing data as  a randomly accessible collection
struct LoopingScrollView<Content: View, Item: RandomAccessCollection>: View where Item.Element: Identifiable {
    /// Custom Properties
    var width: CGFloat
    var spacing: CGFloat = 0
    var items: Item
    @ViewBuilder var content: (Item.Element) -> Content
    var body: some View {
        GeometryReader {
            let size = $0.size
            let repeatingCount = width > 0 ? Int((size.width / width).rounded()) + 1 : 1 // should not == 0

            ScrollView(.horizontal) {
                LazyHStack(spacing: spacing) {
                    ForEach(items) { item in
                        content(item)
                            .frame(width: width)
                    }

                    ForEach(0 ..< repeatingCount, id: \.self) { index in
                        let item = Array(items)[index % items.count]
                        content(item)
                            .frame(width: width)
                    }
                }
                .background {
                    ScrollViewHelper(
                        width: width,
                        spacing: spacing,
                        itemsCount: items.count,
                        repeatingCount: repeatingCount
                    )
                }
            }
        }
    }
}

private struct ScrollViewHelper: UIViewRepresentable {
    var width: CGFloat
    var spacing: CGFloat
    var itemsCount: Int
    var repeatingCount: Int

    func makeCoordinator() -> Coordinator {
        Coordinator(
            width: width,
            spacing: spacing,
            itemsCount: itemsCount,
            repeatingCount: repeatingCount
        )
    }

    func makeUIView(context _: Context) -> UIView {
        .init()
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            if let scrollView = uiView.superview?.superview?.superview as? UIScrollView, !context.coordinator.isAdded {
                scrollView.delegate = context.coordinator
                context.coordinator.isAdded = true
            }
        }
        context.coordinator.width = width
        context.coordinator.spacing = spacing
        context.coordinator.itemsCount = itemsCount
        context.coordinator.repeatingCount = repeatingCount
    }

    class Coordinator: NSObject, UIScrollViewDelegate {
        var width: CGFloat
        var spacing: CGFloat
        var itemsCount: Int
        var repeatingCount: Int

        init(
            width: CGFloat,
            spacing: CGFloat,
            itemsCount: Int,
            repeatingCount: Int
        ) {
            self.width = width
            self.spacing = spacing
            self.itemsCount = itemsCount
            self.repeatingCount = repeatingCount
        }

        /// whether the delegate is added or not
        var isAdded: Bool = false

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            guard itemsCount > 0 else { return }
            let minX = scrollView.contentOffset.x
            let mainContentSize = CGFloat(itemsCount) * width
            let spacingSize = CGFloat(itemsCount) * spacing

            if minX > (mainContentSize + spacingSize) {
                scrollView.contentOffset.x -= (mainContentSize + spacingSize)
            }

            if minX < 0 {
                scrollView.contentOffset.x += (mainContentSize + spacingSize)
            }
        }
    }
}

#Preview {
    InfiniteLoopingScrollDemoView()
}
