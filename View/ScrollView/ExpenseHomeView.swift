//
//  ExpenseHomeView.swift
//  animation
//
//  Standalone demo (not wired into the app's demo browser; preview-only).
//
//  Learning point
//  ──────────────
//  Banking-app home screen with a paged horizontal carousel of
//  expense cards at the top that LOCKS to the navigation bar as
//  the user scrolls past it; the list of recent transactions
//  scrolls underneath. The headline trick is the carousel
//  selectively disabling its own paging behaviour once it has
//  collapsed against the top — so the user can't horizontally swipe
//  cards while the vertical scroll controls the page-stack.
//
//  Two scroll surfaces composed:
//    • Outer vertical ScrollView holds the carousel-as-header + the
//      transactions list.
//    • Inner horizontal carousel with `.scrollTargetBehavior(.paging)`
//      + `.scrollPosition(id:)` for snap-per-card.
//  A `CustomScrollBehavior` (file-local) overrides scroll target
//  behaviour so the carousel doesn't fight the parent vertical
//  scroll once the cards have docked.
//
//  Key APIs
//  ────────
//  • `containerRelativeFrame(.horizontal)` — sizes each card to one
//    full carousel viewport.
//  • `.scrollTargetBehavior(.paging)` + `.scrollPosition(id:)` —
//    the per-card paging snap.
//  • `.visualEffect` driven by scroll offset — drives the carousel's
//    mask/clip as it docks.
//  • Custom `ScrollTargetBehavior` conformance (`CustomScrollBehavior`)
//    — disables horizontal paging once vertical scroll has docked
//    the carousel. The right hook for "this carousel only pages
//    while it's the focused element."
//
//  How to apply
//  ────────────
//  Use whenever a hero/header element should compress to a sticky
//  toolbar as the user scrolls past it (banking, music, fitness).
//  The `CustomScrollBehavior` pattern is the reusable nugget — it
//  generalises beyond carousels to any scroll-within-scroll layout.
//
//  See also
//  ────────
//  • View/ScrollView/CustomHeaderEffect/* — header-collapse
//    siblings; different visual but same "compress on scroll" idea.
//  • View/Carousel/* — the carousel zoo; this file's carousel is
//    a standard `.paging` flavour.
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
                        /// use fix value to help calculate top offset for animation
                        .frame(height: 45)
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
                                            cardView(expenseCard)
                                        } else {
                                            /// Scroll-able
                                            /// Showing only selected card
                                            if activeExpenseCard == expenseCard.id {
                                                cardView(expenseCard)
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
                    Menu {} label: {
                        HStack(spacing: 4) {
                            Text("Filter By")
                            Image(systemName: "chevron.down")
                        }
                        .font(.caption)
                        .foregroundStyle(.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)

                    ForEach(allExpenses) { expense in
                        expenseCardView(expense)
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
        .onChange(of: activeExpenseCard) { _, _ in
            withAnimation(.snappy) {
                allExpenses = expenses.shuffled()
            }
        }
    }

    /// Background Limit Offset
    nonisolated func backgroundLimitOffset(_ proxy: GeometryProxy) -> CGFloat {
        let minY = proxy.frame(in: .scrollView).minY
        ///  adjustable; try 75.0 to see the diff;
        /// the overlapping height is 125 (card height) - 100
        let customHeight: CGFloat = 100.0
        return minY < customHeight ? -minY + customHeight : 0 // 100
    }

    func cardView(_ card: ExpenseCard) -> some View {
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

                    #if DEBUG
                        Text("Current Balance \(offset)")
                            .font(.callout)
                    #endif

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
    func expenseCardView(_ expense: Expense) -> some View {
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
    func updateTarget(_ target: inout ScrollTarget, context _: TargetContext) {
        if target.rect.minY < 75 {
            target.rect = .zero /// reset scroll position
        }
    }
}

#Preview {
    ExpenseHomeView()
}
