//
//  CalendarView.swift
//  animation
//
//  Created on 1/23/26.
import SwiftUI

let monthHeight: CGFloat = 400

struct CalendarView: View {
    @State private var months: [Month] = []
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
            }

            if offsetY < threshold, !isLoadingTop {
                /// Loading past months
            }

        })
        .safeAreaInset(edge: .top, spacing: 0) {
            symbolView()
        }
        .overlay(alignment: .bottom) {
            bottomBar()
        }
        .onAppear(perform: loadInitialData)
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

    private func loadFutureMonths(info _: ScrollInfo) {
        isLoadingBottom = true
        let futureMonths = months.createMonths(10, isPast: false)
        months.append(contentsOf: futureMonths)

        if months.count > 30 { months.removeFirst(10) }
        /// Resetting status in dispatch queue ( avoid infinite creation)
        DispatchQueue.main.async {
            isLoadingBottom = false
        }
    }

    private func loadPastMonths(info _: ScrollInfo) {}

    func loadInitialData() {
        guard months.isEmpty else { return }
        months = Date.now.initialLoadMonths
        ///  Centering scroll position
        let centerOffset = (CGFloat(months.count / 2) * monthHeight) - (monthHeight / 2)
        scrollPosition.scrollTo(y: centerOffset)
    }

    func bottomBar() -> some View {
        HStack {
            Button {
                loadInitialData()
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

struct MonthView: View {
    var month: Month
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(month.name)
                .font(.title2)
                .fontWeight(.bold)

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
                }
            }
        }
    }
}

/// Individual Day View
struct DayView: View {
    var day: Day
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
