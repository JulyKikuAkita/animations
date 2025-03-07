//
//  MintFilterTransactionsView.swift
//  MyMint

import SwiftUI
import SwiftData

struct MintFilterTransactionsView<Content: View>: View {
    var content: ([Transaction]) -> Content
    @Query(animation: .snappy) private var transactions: [Transaction]
    /// category , rule and search text filter
    init(category: MintCategory?, rule: MintRule? ,searchText: String,@ViewBuilder content: @escaping ([Transaction]) -> Content) {
        /// Custom Predicate
        let rawCategoryValue = category?.rawValue ?? ""
        let rawRuleValue = rule?.rawValue ?? ""

        let predicate = #Predicate<Transaction> { transaction in
            return (transaction.title.localizedStandardContains(searchText) ||
            transaction.remarks.localizedStandardContains(searchText)) &&
            (rawCategoryValue.isEmpty ? true : transaction.category == rawCategoryValue)
            && (rawRuleValue.isEmpty ? true : transaction.rule == rawRuleValue)
        }
        _transactions = Query(filter: predicate,sort:[SortDescriptor(\Transaction.dateAdded, order: .reverse)], animation: .snappy)
        self.content = content
    }

    /// date filter
    init(startDate: Date, endDate: Date, @ViewBuilder content: @escaping ([Transaction]) -> Content) {
        let predicate = #Predicate<Transaction> { transaction in
            return transaction.dateAdded >= startDate && transaction.dateAdded <= endDate
        }
        _transactions = Query(filter: predicate,sort:[SortDescriptor(\Transaction.dateAdded, order: .reverse)], animation: .snappy)
        self.content = content
    }

    /// custom filter
    init(startDate: Date, endDate: Date, category: MintCategory?, @ViewBuilder content: @escaping ([Transaction]) -> Content) {
        let rawCategoryValue = category?.rawValue ?? ""
        let predicate = #Predicate<Transaction> { transaction in
            return transaction.dateAdded >= startDate && transaction.dateAdded <= endDate && (rawCategoryValue.isEmpty ? true : transaction.category == rawCategoryValue)
        }
        _transactions = Query(filter: predicate,sort:[SortDescriptor(\Transaction.dateAdded, order: .reverse)], animation: .snappy)
        self.content = content
    }

    var body: some View {
        content(transactions)
    }
}
