//
//  ExpenseHomeView.swift
//  animation
//
import SwiftUI

struct ExpenseHomeView: View {
    /// View Properties
    @State private var allExpenses: [Expense] = []
    /// Environment Values
    @Environment(\.colorScheme) private var scheme
    
    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 15, content: {
                        Text("Hello Nanachi")
                        .font(.largeTitle.bold())
                        .frame(height: 45) /// use fix value to help calculate top offset for animation
                        .padding(.horizontal, 15)
                    
                    GeometryReader {
                        let rect = $0.frame(in: .scrollView)
                        
                        /// Card View
                        ScrollView(.horizontal) {
                            LazyHStack(spacing: 0) {
                                ForEach(expenseCards) { expenseCard in
                                    CardView(expenseCard)
                                        .containerRelativeFrame(.horizontal)
                                }
                            }
                            .scrollTargetLayout()
                        }
                        .scrollTargetBehavior(.paging)
                    }
                    .frame(height: 125)
                })
                
                LazyVStack(spacing: 15) {
                    Menu {
                        
                    } label: {
                        HStack(spacing: 4) {
                            Text("Filter By")
                            Image(systemName: "chevron.down")
                        }
                        .font(.caption)
                        .foregroundStyle(.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    
                    ForEach(allExpenses) { expense in
                            ExpenseCardView(expense)
                    }
                }
                .padding(15)
            }
            .padding(.vertical, 15)
        }
        .scrollIndicators(.hidden)
        .onAppear {
            allExpenses = expenses.shuffled()
        }
    }
    
    @ViewBuilder
    func CardView( _ card: ExpenseCard) -> some View {
        GeometryReader {
            let rect = $0.frame(in: .scrollView(axis: .vertical))
            let minY = rect.minY
            let offset = min(minY - 75, 0) /// 75 is card height 45 + 15 padding + 15 spacing
            ZStack {
                RoundedRectangle(cornerRadius: 25, style: .continuous)
                    .fill(card.bgColor)
                    .overlay(alignment: .leading) {
                        Circle()
                            .fill(card.bgColor)
                            .overlay {
                                Circle()
                                    .fill(.white.opacity(0.2))
                            }
                            .scaleEffect(2, anchor: .topLeading)
                            .offset(x: -50, y: -40)
                    }
                    .clipShape(
                        RoundedRectangle(cornerRadius: 25, style: .continuous)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Spacer(minLength: 0)
                    
                    Text("Current Balance \(offset)") // print offset for debug
                        .font(.callout)
                    
                    Text(card.balance)
                        .font(.title.bold())
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(15)
            }
            .padding(.horizontal, 15)

        }
    }
    
    /// Expense Card View
    @ViewBuilder
    func ExpenseCardView(_ expense: Expense) -> some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.product)
                    .font(.callout)
                    .fontWeight(.semibold)
                
                Text(expense.spendType)
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            
            Spacer(minLength: 0)
            
            Text(expense.amountSpend)
                .fontWeight(.black)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 6)
    }
}

#Preview {
    ExpenseHomeView()
}
