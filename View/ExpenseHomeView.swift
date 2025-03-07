//
//  ExpenseHomeView.swift
//  animation
//
import SwiftUI

struct ExpenseHomeView: View {
    /// View Properties
    @State private var allExpenses: [Expense] = []
    @State private var activeExpenseCard: UUID?
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
                        let minY = rect.minY.rounded()

                        /// Card View
                        ScrollView(.horizontal) {
                            LazyHStack(spacing: 0) {
                                ForEach(expenseCards) { expenseCard in
                                    ZStack {
                                        if minY == 75.0 {
                                            /// Not Scrolled
                                            ///  Showing all cards
                                            CardView(expenseCard)
                                        } else {
                                            /// Scroll-able
                                            /// Showing only selected card
                                            if activeExpenseCard == expenseCard.id {
                                                CardView(expenseCard)
                                            } else {
                                                Rectangle()
                                                    .fill(.clear)
                                            }
                                        }
                                    }
                                    .containerRelativeFrame(.horizontal)
                                }
                            }
                            .scrollTargetLayout()
                        }
                        .scrollPosition(id: $activeExpenseCard)
                        .scrollTargetBehavior(.paging)
                        .scrollClipDisabled()
                        .scrollIndicators(.hidden)
                        .scrollDisabled(minY != 75)
                    }
                    .frame(height: 125) // card height
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
                .mask { // hide expense table under expense card
                    Rectangle()
                        .visualEffect { content, proxy in
                            content
                                .offset(y: backgroundLimitOffset(proxy))
                        }
                }
                .background {
                    GeometryReader {
                        let rect = $0.frame(in: .scrollView)
                        let minY = min(rect.minY - 125, 0)
                        let progress = max(min(-minY / 25, 1), 0)

                        RoundedRectangle(
                            cornerRadius: 30 * progress,
                            style: .continuous
                        )
                            .fill(scheme == .dark ? .black : .white)
                            /// Limiting Background Scroll below the header
                            .visualEffect { content, proxy in
                                content
                                    .offset(y: backgroundLimitOffset(proxy))
                            }
                    }
                }
            }
            .padding(.vertical, 15)
        }
        .scrollTargetBehavior(CustomScrollBehavior())
        .scrollIndicators(.hidden)
        .onAppear {
            if activeExpenseCard == nil {
                activeExpenseCard = expenseCards.first?.id
            }
        }
        .onChange(of: activeExpenseCard) { oldValue, newValue in
            withAnimation(.snappy) {
                allExpenses = expenses.shuffled()
            }
        }
    }


    /// Background Limit Offset
    nonisolated func backgroundLimitOffset(_ proxy: GeometryProxy) -> CGFloat {
        let minY = proxy.frame(in: .scrollView).minY
        let customHeight: CGFloat = 100.0 // adjustable; try 75.0 to see the diff; the overlapping height is 125 (card height) - 100
        return minY < customHeight ? -minY + customHeight : 0 // 100
    }

    @ViewBuilder
    func CardView( _ card: ExpenseCard) -> some View {
        GeometryReader {
            let rect = $0.frame(in: .scrollView(axis: .vertical))
            let minY = rect.minY
            let topValue = 75.0 /// 75 is card height 45 + 15 padding + 15 spacing

            let offset = min(minY - topValue, 0)
            let progress = max(min(-offset / topValue, 1), 0)
            let scale: CGFloat = 1 + progress

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
                    .scaleEffect(scale, anchor: .bottom)

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
                .offset(y: progress * -25)
            }
            .offset(y: -offset)
            /// moving til top edge
            .offset(y: progress * -topValue)

        }
        .padding(.horizontal, 15)

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

/// Custom Scroll Target Behavior
/// aka scrollWillEndDragging in UIKit
struct CustomScrollBehavior: ScrollTargetBehavior {
    func updateTarget(_ target: inout ScrollTarget, context: TargetContext) {
        if target.rect.minY < 75 {
            target.rect = .zero /// reset scroll position
        }
    }
}

#Preview {
    ExpenseHomeView()
}
