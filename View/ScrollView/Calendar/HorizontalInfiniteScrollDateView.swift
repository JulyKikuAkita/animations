//
//  HorizontalInfiniteScrollDateView.swift
//  animation
//
//  Created on 7/4/26.

import SwiftUI

struct InfiniteHScrollDemoView: View {
    @State private var selection: Date = .now
    private let calendar = Calendar.current
    var body: some View {
        VStack {
            HorizontalCalendar(date: $selection) { day in
                let isSelected = calendar.isDate(selection, inSameDayAs: day.date)

                VStack(spacing: 6) {
                    Text(day.weekdaySymbol)
                        .font(.caption)
                        .foregroundStyle(.gray)

                    Text("\(day.value)")
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundStyle(isSelected ? .white : (day.noteFromThisMonth ? .gray : .primary))
                        .frame(width: 38, height: 38)
                        .background {
                            if isSelected {
                                Circle()
                                    .fill(.blue)
                            }
                        }
                        .contentShape(.rect)
                        .onTapGesture {
                            withAnimation(.snappy) {
                                selection = day.date
                            }
                        }
                }
            }
        }
        .padding()
    }
}

struct HorizontalCalendar<Content: View>: View {
    var updatesDateOnScroll: Bool = true
    @Binding var date: Date
    var content: (Day) -> Content

    init(
        updatesDateOnScroll: Bool = true,
        date: Binding<Date>,
        @ContentBuilder content: @escaping (Day) -> Content
    ) {
        self.updatesDateOnScroll = updatesDateOnScroll
        _date = date
        self.content = content

        /// init view with prev, current, next week content
        let weeks: [Week] = (-1 ... 1).compactMap {
            Week.load(from: date.wrappedValue, value: $0)
        }
        self.weeks = weeks
    }

    /// View Properties
    @State private var weeks: [Week]
    @State private var scrollPosition: ScrollPosition = .init()
    @State private var containerSize: CGSize = .zero
    @State private var isLocked: Bool = false
    @State private var lockedID: String?
    /// view starts at center
    @State private var weekIndex: Int = 1

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 0) {
                ForEach(weeks) { week in
                    HStack(spacing: 0) {
                        ForEach(week.days) { day in
                            content(day)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .containerRelativeFrame(.horizontal)
                    .visualEffect { [isLocked, lockedID] content, proxy in
                        let minX = proxy.frame(in: .scrollView(axis: .horizontal)).minX

                        return content
                            .opacity(isLocked ? (lockedID == week.id ? 1 : 0) : 1)
                            .offset(x: isLocked ? -minX : 0)
                    }
                }
            }
        }
        .onAppear {
            if weeks.indices.contains(1) {
                scrollPosition.scrollTo(id: weeks[1].id)
            }
        }
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.paging)
        .scrollPosition($scrollPosition) /// scrollPosition only updates when view content changes
        .defaultScrollAnchor(.center, for: .initialOffset)
        .onGeometryChange(for: CGSize.self) {
            $0.size
        } action: { newValue in
            containerSize = newValue
        }
        .onScrollGeometryChange(for: CGFloat.self) {
            $0.contentOffset.x + $0.contentInsets.leading
        } action: { _, newValue in
            guard containerSize.width != .zero else { return }
            weekIndex = Int((newValue / containerSize.width).rounded())

            let addPreviousWeeks = newValue < 0
            let addNextWeeks = newValue > (containerSize.width * 2)

            if addPreviousWeeks || addNextWeeks, !isLocked {
                guard let firstWeekDate = weeks.first?.days.first?.date else { return }
                guard let lastWeekDate = weeks.last?.days.first?.date else { return }

                let previousTwoWeeks: [Week] = [
                    .load(from: firstWeekDate, value: -2),
                    .load(from: firstWeekDate, value: -1),
                ]

                let nextTwoWeeks: [Week] = [
                    .load(from: lastWeekDate, value: 1),
                    .load(from: lastWeekDate, value: 2),
                ]

                if addPreviousWeeks {
                    lockedID = weeks.first?.id
                } else {
                    lockedID = weeks.last?.id
                }
                isLocked = true

                /// keep array size 3
                if addPreviousWeeks {
                    weeks.insert(contentsOf: previousTwoWeeks, at: 0)
                    weeks.removeLast(2)
                } else {
                    weeks.append(contentsOf: nextTwoWeeks)
                    weeks.removeFirst(2)
                }
            } else {
                /// ensure update only happens after view content update to avoid flicker when scroll
                if isLocked {
                    var transaction = Transaction()
                    transaction.scrollPositionUpdatePreservesVelocity = true
                    withTransaction(transaction) {
                        if addPreviousWeeks {
                            scrollPosition.scrollTo(x: containerSize.width * 2)
                        } else {
                            scrollPosition.scrollTo(x: -containerSize.width * 2)
                        }
                    }
                }

                DispatchQueue.main.async {
                    isLocked = false
                    lockedID = nil
                }
            }
        }
        .onChange(of: weekIndex) { _, newValue in
            if updatesDateOnScroll, weeks.indices.contains(newValue) {
                let symbolIndex = Calendar.current.component(.weekday, from: date) - 1
                date = weeks[newValue].days[symbolIndex].date
            }
        }
    }
}

#Preview {
    InfiniteHScrollDemoView()
}
