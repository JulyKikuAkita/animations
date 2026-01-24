//
//  DummyChartViews.swift
//  animation
//
//  Created on 1/22/26.

import Charts
import SwiftUI

struct DummyChartDemoViews: View {
    var body: some View {
        List {
            ForEach(stocks) { stock in
                StockDummyChartView(stock: stock)
            }
        }
    }
}

struct StockDummyChartView: View {
    let stock: Stock
    var body: some View {
        Chart {
            ForEach(0 ..< stock.sampleGraphData.count, id: \.self) { index in
                let point = stock.sampleGraphData[index]
                let index = Double(index)

                LineMark(x: .value("X", index),
                         y: .value("Y", point * 100))
                    .foregroundStyle(stock.differenceColor)

                AreaMark(
                    x: .value("X", index),
                    y: .value("Y", point * 100)
                )
                .foregroundStyle(stock.differenceColor.opacity(0.2))
            }
        }
        .chartLegend(.hidden)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .frame(height: 15)
        .padding(.horizontal, 10)
    }
}

#Preview {
    DummyChartDemoViews()
}
