//
//  Recents.swift
//  MyMint

import SwiftData
import SwiftUI

struct Recents: View {
    @Query(sort: [SortDescriptor(\Transaction.dateAdded, order: .reverse)], animation: .snappy) private var transactions: [Transaction]
    /// User properties
    @AppStorage("userName") private var userName: String = ""

    /// View Properties
    @State private var startDate: Date = .now.startOfMonth
    @State private var endDate: Date = .now.endOfMonth
    @State private var selectedCategory: MintCategory = .expense
    @State private var showFilterView: Bool = false

    /// Animation properties
    @Namespace private var animation
    var body: some View {
        GeometryReader {
            /// for animation purpose
            let size = $0.size

            NavigationStack {
                ScrollView(.vertical) {
                    LazyVStack(spacing: 10, pinnedViews: [.sectionHeaders]) {
                        Section {
                            /// Date filter button
                            Button(action: {
                                showFilterView = true
                            }, label: {
                                Text("\(format(date: startDate, format: "dd-MMM yy")) to \(format(date: endDate, format: "dd-MMM yy"))"
                                )
                                .font(.caption2)
                                .foregroundStyle(.gray)
                            })
                            .hSpacing(.leading)

                            MintFilterTransactionsView(startDate: startDate, endDate: endDate) { transaction in
                                /// Card view
                                MintCardView(income: total(transactions, category: .income),
                                             expense: total(transactions, category: .expense))

                                /// Segmented control
                                CustomSegmentedControl()
                                    .padding(.bottom, 10)

                                /// when using mock data
                                /// ForEach(mockTransactions.filter({ $0.category == selectedCategory.rawValue }))
                                ForEach(transactions.filter { $0.category == selectedCategory.rawValue }) { transaction in
                                    NavigationLink(value: transaction) {
                                        MintTransactionCardView(showRule: true, transaction: transaction)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                        } header: {
                            HeaderView(size)
                        }
                    }
                    .padding(15)
                }
                .background(.gray.opacity(0.15))
                .blur(radius: showFilterView ? 8 : 0)
                .disabled(showFilterView)
                .navigationDestination(for: Transaction.self) { transaction in
                    MintExpenseView(editTransaction: transaction)
                }
            }
            .overlay {
                if showFilterView {
                    MintDateFilterView(start: startDate, end: endDate, onSubmit: { start, end in
                        startDate = start
                        endDate = end
                        showFilterView = false
                    }, onClose: {
                        showFilterView = false
                    })
                    .transition(.move(edge: .leading))
                }
            }
            .animation(.snappy, value: showFilterView)
        }
    }

    /// Header View
    @ViewBuilder
    func HeaderView(_ size: CGSize) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 5, content: {
                Text("Welcome!")
                    .font(.title.bold())

                if !userName.isEmpty {
                    Text(userName)
                        .font(.callout)
                        .foregroundStyle(.gray)
                }
            })
            .visualEffect { content, geometryProxy in
                content
                    .scaleEffect(headerScale(size, proxy: geometryProxy), anchor: .topLeading)
            }

            Spacer(minLength: 0)

            NavigationLink {
                MintExpenseView()
            } label: {
                Image(systemName: "plus")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(width: 45, height: 45)
                    .background(appTint.gradient, in: .circle)
                    .contentShape(.circle)
            }
        }
        .padding(.bottom, userName.isEmpty ? 10 : 5)
        .background {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(.ultraThinMaterial)

                Divider()
            }
            .visualEffect { content, geometryProxy in
                content
                    .opacity(headerBGOpacity(geometryProxy))
            }
            .padding(.horizontal, -15)
            .padding(.top, -(safeArea.top + 15))
        }
    }

    /// Segment Control
    @ViewBuilder
    func CustomSegmentedControl() -> some View {
        HStack(spacing: 0) {
            ForEach(MintCategory.allCases, id: \.rawValue) { category in
                Text(category.rawValue)
                    .hSpacing()
                    .padding(.vertical, 10)
                    .background {
                        if category == selectedCategory {
                            Capsule()
                                .fill(.background)
                                .matchedGeometryEffect(id: "ACTIVETAB", in: animation)
                        }
                    }
                    .contentShape(.capsule)
                    .onTapGesture {
                        withAnimation(.snappy) {
                            selectedCategory = category
                        }
                    }
            }
        }
        .background(.gray.opacity(0.15), in: .capsule)
        .padding(.top, 5)
    }

    /// scale view along with screen Height: pulldown welcome view enlarge the text
    func headerScale(_ size: CGSize, proxy: GeometryProxy) -> CGFloat {
        let minY = proxy.frame(in: .scrollView).minY
        let screenHeight = size.height

        let progress = minY / screenHeight
        let scale = min(max(progress, 0), 1) * 0.3
        return 1 + scale
    }

    func headerBGOpacity(_ proxy: GeometryProxy) -> CGFloat {
        let minY = proxy.frame(in: .scrollView).minY + safeArea.top
        return minY > 0 ? 0 : (-minY / 15)
    }
}

#Preview {
    ContentView()
}
