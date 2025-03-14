//
//  Expense.swift
//  animation

import Foundation

struct Expense: Identifiable {
    var id: UUID = .init()
    var amountSpend: String
    var product: String
    var spendType: String
}

var expenses: [Expense] = [
    Expense(amountSpend: "$128", product: "Amazon Purchase", spendType: "HomeGoods"),
    Expense(amountSpend: "$11", product: "Youtube TV", spendType: "Streaming"),
    Expense(amountSpend: "$8", product: "Bark", spendType: "Membership"),
    Expense(amountSpend: "$99", product: "Magic Keyboard", spendType: "Products"),
    Expense(amountSpend: "$9", product: "Peloton", spendType: "Membership"),

    Expense(amountSpend: "$10", product: "Instagram", spendType: "Ads expense"),
    Expense(amountSpend: "$100", product: "Facebook", spendType: "Ads expense"),
    Expense(amountSpend: "$348", product: "PhototShop", spendType: "Software"),
    Expense(amountSpend: "$99", product: "Figma", spendType: "Software subscription"),
    Expense(amountSpend: "$1200", product: "Macbook Air", spendType: "Products"),

    Expense(amountSpend: "$39", product: "RHD2", spendType: "Games"),
    Expense(amountSpend: "$89", product: "Magic Mouse", spendType: "Products"),
]
