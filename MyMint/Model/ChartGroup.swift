//
//  ChartGroup.swift
//  MyMint

import SwiftUI

struct ChartGroup: Identifiable {
    let id: UUID = .init()
    var date:Date
    var categories: [ChartCategory]
    var totalIncome: Double
    var totalExpense: Double
    var rule: [ChartRule]
    var totalNeed: Double
    var totalWant: Double
    var totalSave: Double
}

struct ChartCategory: Identifiable {
    let id: UUID = .init()
    var totalValue: Double
    var category: MintCategory
}

struct ChartRulesGroup: Identifiable {
    let id: UUID = .init()
    var date:Date
    var rule: [ChartRule]
    var totalNeed: Double
    var totalWant: Double
    var totalSave: Double
}

struct ChartRule: Identifiable {
    let id: UUID = .init()
    var totalValue: Double
    var rule: MintRule
}
