//
//  ExpenseCard.swift
//  animation

import SwiftUI

struct ExpenseCard: Identifiable {
    var id: UUID = .init()
    var bgColor: Color
    var balance: String
}

var expenseCards: [ExpenseCard] = [
    ExpenseCard(bgColor: .purple, balance: "$125,000"),
    ExpenseCard(bgColor: .pink, balance: "$25,000"),
    ExpenseCard(bgColor: .teal, balance: "$25,000"),
    ExpenseCard(bgColor: .brown, balance: "$5,000"),
]
