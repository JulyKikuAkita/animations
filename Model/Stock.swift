//
//  Stock.swift
//  animation
//
//  Created on 1/21/26.

import SwiftUI

struct Stock: Identifiable {
    var id: String = UUID().uuidString
    var name: String
    var price: String
    var difference: String
    var sampleGraphData: [Double]

    var differenceColor: Color {
        difference.hasPrefix("-") ? .red : .green
    }
}

let dummyStockGraphData: [Double] = [0.1, 0.4, 0.3, 0.8, 0.2, 0.7, 0.6, 0.7, 0.9, 0.1, 0.3, 0.8, 0.1]

let stocks: [Stock] = [
    .init(name: "Apple", price: "$260.25", difference: "+0.88%", sampleGraphData: dummyStockGraphData.shuffled()),
    .init(name: "Google", price: "$312.12", difference: "+3.28%", sampleGraphData: dummyStockGraphData.shuffled()),
    .init(name: "Amazon", price: "$241.34", difference: "-0.02%", sampleGraphData: dummyStockGraphData.shuffled()),
    .init(name: "Tesla", price: "$360.56", difference: "-7.23%", sampleGraphData: dummyStockGraphData.shuffled()),
]
