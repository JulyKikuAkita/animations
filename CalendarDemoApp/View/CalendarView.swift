//
//  CalendarView.swift
//  animation
//
//  Created on 1/23/26.
/// Create infinite scroll of calendar view by load 10 months (before, 5, after 5) of  the current date
/// and set maximum buffer size 30 months in the array to guarantee scroll performance
import SwiftUI

let monthHeight: CGFloat = 400
let monthLotSize: CGFloat = 10
let monthBufferSize = 30

struct CalendarView: View {
    @State private var months: [CalendarMonth] = []
    @State private var scrollPosition: ScrollPosition = .init()
    /// Infinite scroll properties
    @State private var isLoadingTop: Bool = false
    @State private var isLoadingBottom: Bool = false
    @State private var isResetting: Bool = false
    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach(months) { month in
                    MonthView(month: month)
                        .frame(height: monthHeight)
                }
            }
        }
        .scrollPosition($scrollPosition)
        .defaultScrollAnchor(.center)
        .onScrollGeometryChange(for: ScrollInfo.self, of: {
            let offsetY = $0.contentOffset.y + $0.contentInsets.top
            let contentHeight = $0.contentSize.height
            let containerHeight = $0.containerSize.height

            return .init(
                offsetY: offsetY,
                contentHeight: contentHeight,
                containerHeight: containerHeight
            )
        }, action: { _, newValue in
            guard months.count >= 10, !isResetting else { return }

            let threshold: CGFloat = 100
            let offsetY = newValue.offsetY
            let contentHeight = newValue.contentHeight
            let frameHeight = newValue.containerHeight

            if offsetY > (contentHeight - frameHeight - threshold), !isLoadingBottom {
                /// Loading future months
                loadFutureMonths(info: newValue)
            }

            if offsetY < threshold, !isLoadingTop {
                /// Loading past months
                loadPastMonths(info: newValue)
            }

        })
        .background(ScrollToTopDisable())
        .compositingGroup()
        .safeAreaInset(edge: .top, spacing: 0) {
            symbolView()
        }
        .overlay(alignment: .bottom) {
            bottomBar()
        }
        .onAppear {
            guard months.isEmpty else { return }
            loadInitialData()
        }
    }

    func symbolView() -> some View {
        HStack(spacing: 0) {
            ForEach(Calendar.current.shortWeekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 15)
        .overlay(alignment: .bottom) {
            Divider()
        }
        .background(.ultraThinMaterial)
    }

    private func loadFutureMonths(info: ScrollInfo) {
        isLoadingBottom = true
        let futureMonths = months.createMonths(10, isPast: false)
        months.append(contentsOf: futureMonths)

        if months.count > monthBufferSize {
            adjustScrollContentOffset(removeTop: true, info: info)
        }
        /// Resetting status in dispatch queue ( avoid infinite creation)
        DispatchQueue.main.async {
            isLoadingBottom = false
        }
    }

    private func loadPastMonths(info: ScrollInfo) {
        isLoadingTop = true
        let pastMonths = months.createMonths(10, isPast: true)
        months.insert(contentsOf: pastMonths, at: 0)
        adjustScrollContentOffset(removeTop: false, info: info)

        /// Resetting status in dispatch queue ( avoid infinite creation)
        DispatchQueue.main.async {
            isLoadingTop = false
        }
    }

    private func adjustScrollContentOffset(removeTop: Bool, info: ScrollInfo) {
        let previousContentHeight = info.contentHeight
        let previousOffset = info.offsetY
        let adjustmentHeight: CGFloat = monthHeight * monthLotSize

        if removeTop {
            months.removeFirst(10)
        } else {
            if months.count > monthBufferSize { months.removeLast(10) }
        }

        let newContentHeight = previousContentHeight + (removeTop ? -adjustmentHeight : adjustmentHeight)
        let newContentOffset = previousOffset + (newContentHeight - previousContentHeight)

        /// use transaction scroll property  to avoid scroll stop on setting scroll position
        var transaction = Transaction()
        transaction.scrollPositionUpdatePreservesVelocity = true
        withTransaction(transaction) {
            scrollPosition.scrollTo(y: newContentOffset)
        }
    }

    func loadInitialData() {
        months = Date.now.initialLoadMonths
        ///  Centering scroll position
        let centerOffset = (CGFloat(months.count / 2) * monthHeight) - (monthHeight / 2)
        scrollPosition.scrollTo(y: centerOffset)
    }

    func bottomBar() -> some View {
        HStack {
            Button {
                isResetting = true
                loadInitialData()
                DispatchQueue.main.async {
                    isResetting = false
                }
            } label: {
                Text("Today")
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.primary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(.background, in: .capsule)
            }

            Spacer(minLength: 0)

            Text("Array Count: \(months.count)")
                .fontWeight(.semibold)
                .foregroundStyle(Color.primary)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(.background, in: .capsule)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity)
        .background {
            /// progress view blur effect
            Rectangle()
                .fill(.ultraThinMaterial)
                .mask {
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.white.opacity(0.7),
                            Color.white,
                            Color.white,
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .padding(.top, -30)
                .ignoresSafeArea()
        }
    }
}

/// Setting month Height to 350:
///  title of the view: 50
///  each week height 50, max 6 weeks in a month = 50 * 6
/// Not using dynamic height here b.c use scroll content offset -> need to know the exact height of the content to be added/removed
struct MonthView: View {
    var month: CalendarMonth
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(month.name)
                .font(.title2)
                .fontWeight(.bold)
                .frame(height: 50, alignment: .bottom)

            /// Weeks View
            VStack(spacing: 0) {
                ForEach(month.weeks) { week in
                    HStack(spacing: 0) {
                        /// Days View
                        ForEach(week.days) { day in
                            DayView(day: day)
                        }
                    }
                    .frame(maxHeight: .infinity)
                    .overlay(alignment: .bottom) {
                        if !week.isLast {
                            Divider()
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 15)
    }
}

/// Individual Day View
struct DayView: View {
    var day: CalendarDay
    var body: some View {
        if let dayValue = day.value, let date = day.date, !day.isPlaceholder {
            let isToday = Calendar.current.isDateInToday(date)

            Text("\(dayValue)")
                .font(.callout)
                .fontWeight(isToday ? .semibold : .regular)
                .foregroundStyle(isToday ? .white : .primary)
                .frame(width: 30, height: 50)
                .background {
                    if isToday {
                        Circle()
                            .fill(.blue.gradient)
                    }
                }
                .frame(maxWidth: .infinity)
        } else {
            Color.clear
        }
    }
}

#Preview {
    CalendarView()
}
