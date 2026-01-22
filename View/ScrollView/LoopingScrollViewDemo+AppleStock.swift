//
//  LoopingScrollViewDemo+AppleStock.swift
//  animation
//
//  Created on 1/21/26.

import SwiftUI

struct LoppingScrollDemoView: View {
    var body: some View {
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

                Rectangle()
                    .frame(height: 40)
            }
        }
        .frame(height: 120)
    }
}

struct LoopingScrolliOS26View<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable {
    var spacing: CGFloat = 10
    var itemWidth: CGFloat
    var data: Data
    @ViewBuilder var content: (_ item: Data.Element, _ isRepeated: Bool) -> Content

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: spacing) {
                ForEach(data) { item in
                    content(item, false)
                        .frame(width: itemWidth)
                }
            }
        }
    }
}

#Preview {
    LoppingScrollDemoView()
}
