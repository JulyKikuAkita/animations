//
//  Transaction.swift
//  MyMint

import SwiftUI
import SwiftData

@Model
class Transaction {
    /// Properties
    var title: String
    var remarks: String
    var amount: Double
    var dateAdded: Date
    var category: String
    var rule: String
    var tintColor: String
    
    init(title: String, remarks: String, amount: Double, dateAdded: Date, category: MintCategory, rule: MintRule, tintColor: TintColor) {
        self.title = title
        self.remarks = remarks
        self.amount = amount
        self.dateAdded = dateAdded
        self.category = category.rawValue
        self.rule = rule.rawValue
        self.tintColor = tintColor.color
    }
    
    /// Extracting color value from tintColor String
    ///  Note: by default, SwiftData does not persist computed properties but still annotate @Transient below for learning purpose
    @Transient
    var color: Color {
        return tints.first(where: { $0.color == tintColor })?.value ?? appTint
    }
    
    @Transient
    var tint: TintColor? {
        return tints.first(where: { $0.color == tintColor })
    }
    
    @Transient
    var rawCategory: MintCategory? {
        return MintCategory.allCases.first(where: { category == $0.rawValue })
    }
    
    @Transient
    var rawRule: MintRule? {
        return MintRule.allCases.first(where: { rule == $0.rawValue })
    }
}

///// mock data
//var mockTransactions: [Transaction] = [
//    .init(title: "Magic Mike", remarks: "McDonald's", amount: 39.99, dateAdded: .now, category: .expense, rule: .need, tintColor: tints.randomElement()!),
//    .init(title: "Magic Keyboard", remarks: "Apple", amount: 129.99, dateAdded: .now, category: .expense, rule: .need, tintColor: tints.randomElement()!),
//    .init(title: "Magic Wand", remarks: "Disnet", amount: 99.99, dateAdded: .now, category: .expense, rule: .want, tintColor: tints.randomElement()!),
//    .init(title: "Garage sell", remarks: "FB market place", amount: 799.99, dateAdded: .now, category: .income, rule: .save, tintColor: tints.randomElement()!),
//]
