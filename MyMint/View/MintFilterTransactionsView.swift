//
//  MintFilterTransactionsView.swift
//  MyMint

import SwiftUI
import SwiftData

struct MintFilterTransactionsView<Content: View>: View {
    var content: ([Transaction]) -> Content
    @Query(animation: .snappy) private var transactions: [Transaction]
    init(category: MintCategory?, rule: MintRule? ,searchText: String,@ViewBuilder content: @escaping ([Transaction]) -> Content) {
        /// Custom Predicate
        let rawCategoryValue = category?.rawValue ?? ""
        let rawRuleValue = rule?.rawValue ?? ""
        
        let predicate = #Predicate<Transaction> { transaction in
            return (transaction.title.localizedStandardContains(searchText) ||
            transaction.remarks.localizedStandardContains(searchText)) &&
            (rawCategoryValue.isEmpty ? true : transaction.capacity == rawCategoryValue) &&
            (rawRuleValue.isEmpty ? true : transaction.rule == rawRuleValue)
        }
        _transactions = Query(filter: predicate,sort:[SortDescriptor(\Transaction.dateAdded, order: .reverse)], animation: .snappy)
        self.content = content
    }
    var body: some View {
        content(transactions)
    }
}
