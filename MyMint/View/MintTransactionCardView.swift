//
//  MintTransactionCardView.swift
//  MyMint

import SwiftUI

struct MintTransactionCardView: View {
    @Environment(\.modelContext) private var context
    var showCategory: Bool = false
    var showRule: Bool = false
    var transaction: Transaction
    var body: some View {
        SwipeAction(cornerRadius: 10, direction: .trailing) {
            HStack(spacing: 12) {
                Text("\(String(transaction.title.prefix(1)))")
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(width: 45, height: 45)
                    .background(transaction.color.gradient, in: .circle)

                VStack(alignment: .leading, spacing: 4, content: {
                    Text(transaction.title)
                        .foregroundStyle(Color.primary)

                    Text(transaction.remarks)
                        .font(.caption)
                        .foregroundStyle(Color.secondary)

                    Text(format(date: transaction.dateAdded, format: "dd MMM yyyy"))
                        .font(.caption2)
                        .foregroundStyle(.gray)

                    if showCategory {
                        Text(transaction.category)
                            .font(.caption2)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .foregroundColor(.white)
                            .background(transaction.category == MintCategory.income.rawValue ? Color.green.gradient : Color.red.gradient, in: .capsule)
                    }

                    if showRule {
                        Text(transaction.rule)
                            .font(.caption2)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(wantLabelTint, in: .capsule)
                    }
                })
                .lineLimit(1)
                .hSpacing(.leading)

                Text(currencyString(transaction.amount, allowedDigits: 2))
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 10)
            .background(.background, in: .rect(cornerRadius: 10))
        } actions: {
            Action(tint: .red, icon: "trash") {
                context.delete(transaction)
            }
        }
    }
}

#Preview {
    ContentView()
}
