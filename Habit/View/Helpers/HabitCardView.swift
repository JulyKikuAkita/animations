//
//  HabitCardView.swift
//  Habit

import SwiftUI

struct HabitCardView: View {
    var animationID: Namespace.ID
    var habit: Habit
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(habit.name)
                        .font(.callout)
                    
                    Text("Created At" + habit.createdAt.format("dd, MM YYYY"))
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
                Spacer(minLength: 0)
                
                CompletionProgressIndicator()
            }
            
            HabitCalendarView(
                createdAt: habit.createdAt,
                frequency: habit.frequency,
                completedDates: habit.completedDates
            )
            .applyPaddedBackground(10)
            /// Zoom Transition Effect
            .matchedTransitionSource(id: habit.uniqueID, in: animationID)
        }
    }
    
    @ViewBuilder
    func CompletionProgressIndicator() -> some View {
        let habitMatchingDatesInThisMonth = Date.datesInThisMonth.filter {  date in
            habit.frequency.contains {
                $0.rawValue == date.weekDay
            } && date.startOfDay >= habit.createdAt.startOfDay
        }
        
        let habitsCompletedInThisMonth = habitMatchingDatesInThisMonth.filter {
            habit.completedDates.contains($0.timeIntervalSince1970)
        }
        
        let progress = CGFloat(habitsCompletedInThisMonth.count) / CGFloat(habitMatchingDatesInThisMonth.count)
        
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(.fill, lineWidth: 3)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(.green.gradient, lineWidth: 3)
                    .rotationEffect(.init(degrees: -90))
            }
            .frame(width:30, height: 30)
            
            Text("\(progress * 100)%")
            Text("\(habitsCompletedInThisMonth.count)/\(habitMatchingDatesInThisMonth.count)")
                .font(.caption2)
                .foregroundStyle(.gray)
        }
    }
}
