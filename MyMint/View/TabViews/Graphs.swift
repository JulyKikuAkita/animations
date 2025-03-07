//
//  Graphs.swift
//  MyMint

import SwiftUI
import SwiftData
import Charts
// https://www.youtube.com/watch?v=qQ3NGkv8O8c&list=PLimqJDzPI-H88PbxlOtNPkD0n0n-q-__z&index=8
// TODO: widget: 13:31
struct Graphs: View {
    /// View properties
    @Query(animation: .snappy) private var transactions: [Transaction]
    @State private var chartGroups: [ChartGroup] = []
    @State private var showPieChart: Bool = false
    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                Button(action: {
                    showPieChart.toggle()
                }, label: {
                    ZStack {
                        Image(systemName: "chart.pie")
                            .opacity(showPieChart ? 0 : 1)
                        if showPieChart {
                            PieChartView()
                        }
                    }
                })
//                .frame(height: 50)
//                .padding(10)
//                .padding(.top, 10)
//                .background(.background, in: .rect(cornerRadius: 10))

                LazyVStack(spacing: 10) {
                    ChartView()
                        .frame(height: 200)
                        .padding(10)
                        .padding(.top, 10)
                        .background(.background, in: .rect(cornerRadius: 10))



                    ForEach(chartGroups) { group in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(format(date: group.date, format: "MMM yy"))
                                .font(.caption)
                                .foregroundStyle(.gray)
                                .hSpacing(.leading)

                            NavigationLink {
                                ListOfExpenses(month: group.date)
                            } label: {
                                MintCardView(income: group.totalIncome, expense: group.totalExpense)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(15)
            }
            .navigationTitle("Graphs")
            .background(.gray.opacity(0.15))
            .onAppear {
                createChartGroup()
            }
        }
    }

    @ViewBuilder
    func ChartView() -> some View {
        /// Chart View
        Chart {
            ForEach(chartGroups) { group in
                ForEach(group.categories) { chart in
                    BarMark(
                        x: .value("Month", format(date: group.date, format: "MMM yy")),
                        y: .value(chart.category.rawValue, chart.totalValue),
                        width: 20
                    )
                    .position(by: .value("Category", chart.category.rawValue), axis: .horizontal)
                    .foregroundStyle(by: .value("Category", chart.category.rawValue))
                }
            }
        }
        /// Marking chart scrollable
        .chartScrollableAxes(.horizontal)
        /// Set space between bar marks
        .chartXVisibleDomain(length: 4)
        .chartLegend(position: .bottom, alignment: .trailing)
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                let doubleValue = value.as(Double.self) ?? 0

                AxisGridLine()
                AxisTick()
                AxisValueLabel {
                    Text(axisLabel(doubleValue))
                }
            }
        }
        /// Foreground colors
        .chartForegroundStyleScale(range: [Color.green.gradient, Color.red.gradient])
    }

    func createChartGroup() {
        Task.detached(priority: .high) {
            let calendar = Calendar.current

            let groupByDate = Dictionary(grouping: transactions) { transaction in
                let components = calendar.dateComponents([.month, .year], from: transaction.dateAdded)
                return components
            }

            /// Sorting groups by date
            let sortedGroup = groupByDate.sorted {
                let date1 = calendar.date(from: $0.key) ?? .init()
                let date2 = calendar.date(from: $1.key) ?? .init()

                return calendar.compare(date1, to: date2, toGranularity: .day) == .orderedDescending
            }

            let chartGroups = sortedGroup.compactMap { dict -> ChartGroup? in
                let date = calendar.date(from: dict.key) ?? .init()
                /// category
                let income = dict.value.filter({ $0.category == MintCategory.income.rawValue})
                let expense = dict.value.filter({ $0.category == MintCategory.expense.rawValue})

                let incomeTotalValue = total(income, category: .income)
                let expenseTotalValue = total(expense, category: .expense)

                /// rule
                let need = dict.value.filter({ $0.rule == MintRule.need.rawValue})
                let want = dict.value.filter({ $0.rule == MintRule.want.rawValue})
                let save = dict.value.filter({ $0.rule == MintRule.save.rawValue})

                let  totalNeed = total(need, rule: .need)
                let  totalWant = total(want, rule: .want)
                let  totalSave = total(save, rule: .save)
                return .init(
                    date: date,
                    categories: [
                        .init(totalValue: incomeTotalValue, category: .income),
                        .init(totalValue: expenseTotalValue, category: .expense)
                    ],
                    totalIncome: incomeTotalValue,
                    totalExpense: expenseTotalValue,
                    rule: [
                        .init(totalValue: totalNeed, rule: .need),
                        .init(totalValue: totalWant, rule: .want),
                        .init(totalValue: totalSave, rule: .save)
                    ],
                    totalNeed: totalNeed,
                    totalWant: totalWant,
                    totalSave: totalSave
                )
            }

            /// UI must be updated on Main thread
            await MainActor.run {
                self.chartGroups = chartGroups
            }
        }
    }

    func axisLabel(_ value: Double) -> String {
        let intValue = Int(value)
        let kValue = intValue / 1000
        return intValue < 1000 ? "\(intValue)" : "\(kValue)K"
    }

    @ViewBuilder
    func PieChartView() -> some View {
        /// Pie Chart View
        Chart {
            ForEach(chartGroups) { group in
                ForEach(group.categories) { rule in
                        SectorMark(
                            angle: .value(rule.category.rawValue, rule.totalValue),
                            innerRadius: .ratio(0),
                            outerRadius: .ratio(1.0)
                        )
                        .foregroundStyle(by: .value("Category", colorBarMark(for: group, ruleValue: rule.totalValue)))
                    }
            }
        }
        /// Marking chart scrollable
        .chartScrollableAxes(.horizontal)
        .chartLegend(position: .bottom, alignment: .trailing)
        /// Foreground colors
        .chartForegroundStyleScale(range: [
            Color.orange.gradient,
            Color.blue.gradient,
            Color.brown.gradient,
            Color.pink.gradient])
    }

    func colorBarMark(for data: ChartGroup, ruleValue: Double) -> Double {
        let categoryTotal = data.totalExpense + data.totalIncome
        let ruleTotal = data.totalNeed + data.totalWant + data.totalSave
        guard categoryTotal ==  ruleTotal else { return 0.0 }
        let proportion = ruleValue / ruleTotal
        return proportion
    }
}


struct ListOfExpenses: View {
    var month: Date
    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 15) {
                Section {
                    MintFilterTransactionsView(startDate: month.startOfMonth, endDate: month.endOfMonth, category: .income) {
                        transactions in
                        ForEach(transactions) { transaction in
                            NavigationLink {
                                MintExpenseView(editTransaction: transaction)
                            } label: {
                                MintTransactionCardView(transaction: transaction)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } header: {
                    Text("Income")
                        .font(.caption)
                        .foregroundStyle(.gray)
                        .hSpacing(.leading)
                }

                Section {
                    MintFilterTransactionsView(startDate: month.startOfMonth, endDate: month.endOfMonth, category: .expense) {
                        transactions in
                        ForEach(transactions) { transaction in
                            NavigationLink {
                                MintExpenseView(editTransaction: transaction)
                            } label: {
                                MintTransactionCardView(transaction: transaction)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } header: {
                    Text("Expense")
                        .font(.caption)
                        .foregroundStyle(.gray)
                        .hSpacing(.leading)
                }
            }
        }
        .background(.gray.opacity(0.15))
        .navigationTitle(format(date: month, format: "MMM yy"))
    }
}
#Preview {
    Graphs()
}
