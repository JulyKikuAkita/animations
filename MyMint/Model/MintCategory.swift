//
//  MintCategory.swift
//  MyMint

import SwiftUI

enum MintCategory: String, CaseIterable {
    case income = "Income"
    case expense = "Expense"
}

enum MintRule: String, CaseIterable {
    case need = "Need"
    case want = "Want"
    case save = "Save"
}
