//
//  HabitCalendarView.swift
//  Habit

import SwiftUI

struct HabitCalendarView: View {
    var createdAt: Date
    var frequency: [HabitFrequency]
    var completedDates: [TimeInterval]
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(), count: 7), spacing: 12) {
            ForEach(HabitFrequency.allCases, id: \.rawValue) { frequency in
                Text(frequency.rawValue.prefix(3))
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            
            /// day 1 of the month  always start on Sundays, add offset to push it to draw at the  actual date
            ForEach(0..<Date.startOffsetOfThisMonth, id: \.self) { _ in
                Circle()
                    .fill(.clear)
                    .frame(height: 30)
                    .hSpacing(.center)
            }
            
            ForEach(Date.datesInThisMonth, id: \.self) { date in
                let day = date.format("dd")
                
                Text(day)
                    .font(.caption)
                    .frame(height: 30)
                    .hSpacing(.center)
                    .background {
                        let isHabitCompleted = completedDates.contains {
                            $0 == date.timeIntervalSince1970
                        }
                        
                        /// Habit day should be marked after the created date
                        let isHabitDay = frequency.contains {
                            $0.rawValue == date.weekDay
                        } && date.startOfDay >= createdAt.startOfDay
                        
                        let isFutureHabits = date.startOfDay > Date()
                        
                        if isHabitCompleted && isHabitDay {
                            Circle()
                                .fill(.green.tertiary)
                        } else if isHabitDay && !isFutureHabits {
                            Circle()
                                .fill(.red.tertiary)
                        } else {
                            if isHabitDay {
                                Circle()
                                    .fill(.fill)
                            }
                        }
                    }
            }
        }
    }
}

#Preview {
    HabitCalendarView(
        createdAt: .now,
        frequency: [.sunday, .wednesday, .saturday],
        completedDates: [])
}
