//
//  LoopingScrollViewDemo+AppleStock.swift
//  animation
//
//  Created on 1/21/26.

import Charts
import Combine
import SwiftUI

struct LoppingScrollDemoView: View {
    @State private var showSheet: Bool = true
    @State private var currentDetent: PresentationDetent = .height(150)
    var body: some View {
        NavigationStack {
            VStack {
                headerView()
                Spacer(minLength: 0)
            }
        }
        .sheet(isPresented: $showSheet) {
            VStack {
                Capsule()
                    .frame(height: 15)
                Spacer(minLength: 0)
            }
            .presentationDetents([.height(150), .fraction(0.4), .fraction(0.91)], selection: $currentDetent)
            .presentationBackgroundInteraction(.enabled)
            .interactiveDismissDisabled()
        }
    }

    func headerView() -> some View {
        let isHeaderDisabled: Bool = currentDetent == .fraction(0.91)
        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Stocks")
                    .font(.title2)
                    .fontWeight(.bold)

                Text(Date.now, style: .date)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.gray)
            }

            Spacer(minLength: 0)

            HStack(spacing: 20) {
                Button {} label: {
                    Image(systemName: "magnifyingglass")
                }

                Button {} label: {
                    Image(systemName: "ellipsis")
                }
            }
            .foregroundStyle(.primary)
            .font(.title3)
            .padding(15)
            .background(.bar, in: .capsule)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .opacity(isHeaderDisabled ? 0 : 1)
        .padding(.horizontal, 15)
        .overlay {
            if isHeaderDisabled {
                stockAutoScrollView()
                    .transition(.opacity)
            }
        }
        .frame(height: 80)
        .animation(.snappy(duration: 0.3, extraBounce: 0), value: isHeaderDisabled)
    }

    func stockAutoScrollView() -> some View {
        LoopingScrolliOS26View(itemWidth: 180, data: stocks) { stock, _ in
            HStack(spacing: 15) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(stock.name)
                        .font(.callout)
                        .fontWeight(.semibold)

                    Text(stock.price)
                        .font(.system(size: 17, weight: .bold))

                    Text(stock.difference)
                        .font(.callout)
                        .fontWeight(.semibold)
                        .foregroundStyle(stock.differenceColor)
                }

                StockDummyChartView(stock: stock)
            }
        }
        .frame(height: 120)
    }
}

struct LoopingScrolliOS26View<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable {
    var spacing: CGFloat = 10
    var scrollSpeed: CGFloat = 0.7 // [0,1]
    var itemWidth: CGFloat
    var data: Data
    @ViewBuilder var content: (_ item: Data.Element, _ isRepeated: Bool) -> Content
    /// View Properties
    @State private var scrollPosition: ScrollPosition = .init()
    @State private var containerWidth: CGFloat = 0
    @State private var currentOffset: CGFloat = 0
    @State private var repeatingCount: Int = 0

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: spacing) {
                /// Original Items
                HStack(spacing: spacing) {
                    ForEach(data) { item in
                        content(item, false)
                            .frame(width: itemWidth)
                    }
                }

                /// Repeated Items
                HStack(spacing: spacing) {
                    ForEach(0 ..< repeatingCount, id: \.self) { index in
                        let actualIndex = index % data.count
                        let itemIndex = data.index(data.startIndex, offsetBy: actualIndex)
                        content(data[itemIndex], true)
                            .frame(width: itemWidth)
                    }
                }
            }
        }
        .scrollPosition($scrollPosition)
        .scrollIndicators(.hidden)
        /// Calculating how many repeating items to make looping scroll effect
        .onScrollGeometryChange(for: CGFloat.self) {
            $0.containerSize.width
        } action: { _, newValue in
            let containerWidth = newValue
            let safeValue = 1
            let neededCount = (containerWidth / (itemWidth + spacing)).rounded()
            repeatingCount = Int(neededCount) + safeValue
            self.containerWidth = containerWidth
        }
        .onScrollGeometryChange(for: CGFloat.self) {
            $0.contentOffset.x + $0.contentInsets.leading
        } action: { _, newValue in
            currentOffset = newValue
            guard repeatingCount > 0 else { return }

            let contentWidth = CGFloat(data.count) * itemWidth
            let contentSpacing = CGFloat(data.count) * spacing
            let totalContentWidth = contentWidth + contentSpacing

            let resetOffset = min(totalContentWidth - newValue, 0)

            /// Resetting scroll without disturbing ongoing scroll interaction using transaction
            if resetOffset < 0 || newValue < 0 {
                var transaction = Transaction()
                transaction.scrollPositionUpdatePreservesVelocity = true

                withTransaction(transaction) {
                    if newValue < 0 {
                        /// Backward Reset
                        scrollPosition.scrollTo(x: totalContentWidth)
                    } else {
                        /// Forward Reset
                        scrollPosition.scrollTo(x: resetOffset)
                    }
                }
            }
        }
        /// Auto scrolling - default stops at view interaction while .common mode does not
        .onReceive(Timer.publish(every: 0.01, on: .main, in: .default).autoconnect()) { _ in
            scrollPosition.scrollTo(x: currentOffset + scrollSpeed)
        }
    }
}

#Preview {
    LoppingScrollDemoView()
}
