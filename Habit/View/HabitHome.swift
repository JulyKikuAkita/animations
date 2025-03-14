//
//  HabitHome.swift
//  Habit

import SwiftData
import SwiftUI

struct HabitHome: View {
    @AppStorage("username") private var username: String = ""
    /// View Properties
    @Query(sort: [.init(\Habit.createdAt, order: .reverse)], animation: .snappy) private var habits: [Habit]
    @State private var selectedHabit: Habit?

    @Namespace private var animationID
    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 15) {
                HeaderView()
                    .padding(.bottom, 15)

                ForEach(habits) { habit in
                    HabitCardView(animationID: animationID, habit: habit)
                        .onTapGesture {
                            selectedHabit = habit
                        }
                }
            }
            .padding(15)
            .overlay {
                if habits.isEmpty {
                    ContentUnavailableView("Start tracking your habit", systemImage: "checkmark.circle.fill")
                        .fixedSize(horizontal: false, vertical: true)
                        .visualEffect { content, proxy in
                            content
                                .offset(y: ((proxy.bounds(of: .scrollView)?.height ?? 0) - 50) / 2)
                        }
                        .offset(y: 20)
                }
            }
        }
        .toolbarVisibility(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            CreateButton()
        }
        .background {
            Rectangle()
                .fill(.primary.opacity(0.05))
                .ignoresSafeArea()
                .scaleEffect(1.5) /// avoid weird animation transition
        }
        .navigationDestination(item: $selectedHabit) { selectedHabit in
            HabitCreationView(habit: selectedHabit)
                .navigationTransition(.zoom(sourceID: selectedHabit.uniqueID, in: animationID))
        }
    }

    @ViewBuilder
    func HeaderView() -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Welcome Back!")
                .font(.largeTitle.bold())

            HStack(spacing: 0) {
                Text(username)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                Text(", " + Date.startDateOfThisMonth.format("MMMM YY"))
                    .textScale(.secondary)
                    .foregroundStyle(.gray)
            }
            .font(.title3)
        }
        .hSpacing(.leading)
    }

    @ViewBuilder
    func CreateButton() -> some View {
        NavigationLink {
            HabitCreationView()
                .navigationTransition(.zoom(sourceID: "CREATEBUTTON", in: animationID))
        } label: {
            HStack(spacing: 10) {
                Text("Create Habit")

                Image(systemName: "plus.circle.fill")
            }
            .foregroundStyle(.white)
            .fontWeight(.semibold)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(.green.gradient, in: .capsule)
            .matchedTransitionSource(id: "CREATEBUTTON", in: animationID)
        }
        .hSpacing(.center)
        .padding(.vertical, 10)
        .background { /// Progressive background masking
            Rectangle()
                .fill(.background)
                .mask {
                    Rectangle()
                        .fill(.linearGradient(colors: [
                            .white.opacity(0),
                            .white.opacity(0.5),
                            .white,
                            .white,
                        ], startPoint: .top, endPoint: .bottom))
                }
                .ignoresSafeArea()
        }
    }
}

#Preview {
    NavigationStack {
        ContentView()
    }
}
