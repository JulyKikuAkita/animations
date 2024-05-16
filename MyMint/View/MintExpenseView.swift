//
//  MintExpenseView.swift
//  MyMint

import SwiftUI

struct MintExpenseView: View {
    /// Environment Properties
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    var editTransaction: Transaction?
    /// View Properties
    @State private var title: String = ""
    @State private var remarks: String = ""
    @State private var amount: Double = .zero
    @State private var dateAdded: Date = .now
    @State private var category: MintCategory = .expense
    @State private var rule: MintRule = .need

    /// Random Tint
    @State private var tint: TintColor = tints.randomElement()!
   
    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 15) {
                Text("Preview")
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .hSpacing(.leading)
                
                /// tmp trans view
                MintTransactionCardView(transaction: .init(
                    title: title.isEmpty ? "Title" : title,
                    remarks: remarks.isEmpty ? "Remarks" : remarks,
                    amount: amount,
                    dateAdded: dateAdded,
                    category: category,
                    rule: rule,
                    tintColor: tint
                ))
                
                CustomSection("Title", "Magic Mike", value: $title)
                CustomSection("Remarks", "Magic Mike 2", value: $remarks)
                
                /// Amount & Category Check box
                VStack(alignment: .leading, spacing: 10, content: {
                    Text("Amount & Category")
                        .font(.caption)
                        .foregroundStyle(.gray)
                        .hSpacing(.leading)
                    
                    HStack(spacing: 15) {
                        HStack(spacing: 4) {
                            Text(currencySymbol)
                                .font(.callout.bold())
                            
                            TextField("0.0", value: $amount, formatter: numberFormatter)
                                .keyboardType(.decimalPad)
                        }
                        .padding(.horizontal, 15)
                        .padding(.vertical, 12)
                        .background(.background, in: .rect(cornerRadius: 10))
                        .frame(maxWidth: 130)
                        
                        /// Custom Check Box
                        CustomCategoryCheckBox()
                    }
                    
                    CustomRuleCheckBox()
                })
                
                /// Date picker
                VStack(alignment: .leading, spacing: 10, content: {
                    Text("Date")
                        .font(.caption)
                        .foregroundStyle(.gray)
                        .hSpacing(.leading)
                    
                    DatePicker("", selection: $dateAdded, displayedComponents: [.date])
                        .font(.footnote)
                        .datePickerStyle(.graphical)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 12)
                        .background(.background, in: .rect(cornerRadius: 10))
                    
                })
            }
            .padding(15)
        }
        .navigationTitle("\(editTransaction == nil ? "Add" : "Edit") Transaction")
        .background(.gray.opacity(0.15))
        .toolbar(content: {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save", action: save)
            }
        })
        .onAppear(perform: {
            /// Load all existing data from the transaction
            if let editTransaction {
                title = editTransaction.title
                remarks =  editTransaction.remarks
                amount = editTransaction.amount
                dateAdded = editTransaction.dateAdded
                if let category = editTransaction.rawCategory {
                    self.category = category
                }
               
                if let rule = editTransaction.rawRule {
                    self.rule = rule
                }
                
                if let tint = editTransaction.tint {
                    self.tint = tint
                }
            }
        })
    }
    
    /// Saving transaction
    func save() {
        /// Saving transaction to SwiftData
        if editTransaction != nil {
            editTransaction?.title = title
            editTransaction?.remarks = remarks
            editTransaction?.amount = amount
            editTransaction?.dateAdded = dateAdded
            editTransaction?.category = category.rawValue
            editTransaction?.rule = rule.rawValue
        } else {
            let transaction = Transaction(
                title: title,
                remarks: remarks,
                amount: amount,
                dateAdded: dateAdded,
                category: category,
                rule: rule,
                tintColor: tint
            )
            context.insert(transaction)
        }
        /// Dismiss view
        dismiss()
    }
    
    @ViewBuilder
    func CustomSection(_ title: String, _ hint: String, value: Binding<String>) -> some View {
        VStack(alignment: .leading,spacing: 10, content: {
            Text(title)
                .font(.caption)
                .foregroundStyle(.gray)
                .hSpacing(.leading)
            
            TextField(hint, text: value)
                .padding(.horizontal, 15)
                .padding(.vertical, 12)
                .background(.background, in: .rect(cornerRadius: 10))
        })
    }
    
    @ViewBuilder
    func CustomCategoryCheckBox() -> some View {
        HStack(spacing: 10) {
            ForEach(MintCategory.allCases, id:\.rawValue) { current in
                HStack(spacing: 5) {
                    ZStack {
                        Image(systemName: "circle")
                            .font(.title3)
                            .foregroundStyle(appTint)
                        
                        if self.category == current {
                            Image(systemName: "circle.fill")
                                .font(.caption)
                                .foregroundStyle(appTint)
                        }
                    }
                    
                    Text(current.rawValue)
                        .font(.caption)
                }
                .contentShape(.rect)
                .onTapGesture {
                    self.category = current
                }
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 12)
        .hSpacing(.leading)
        .background(.background, in: .rect(cornerRadius: 10))
    }
    
    @ViewBuilder
    func CustomRuleCheckBox() -> some View {
        HStack(spacing: 5) {
            ForEach(MintRule.allCases, id:\.rawValue) { current in
                HStack(spacing: 5) {
                    ZStack {
                        Image(systemName: "circle")
                            .font(.title3)
                            .foregroundStyle(appTint)
                        
                        if self.rule == current {
                            Image(systemName: "circle.fill")
                                .font(.caption)
                                .foregroundStyle(appTint)
                        }
                    }
                    
                    Text(current.rawValue)
                        .font(.caption)
                }
                .contentShape(.rect)
                .onTapGesture {
                    self.rule = current
                }
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 12)
        .hSpacing(.leading)
        .background(.background, in: .rect(cornerRadius: 10))
    }
    
    /// Number Formatter
    var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter
    }
}

#Preview {
    ContentView()
}
