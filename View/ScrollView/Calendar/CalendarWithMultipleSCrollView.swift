//
//  CalendarWithMultipleSCrollView.swift
//  animation
//

import SwiftUI

struct CalendarWithMultipleHomeView: View {
    @State private var currentWeek: [Date.Day] = Date.currentWeek
    @State private var selectedDate: Date?
    @Namespace private var animation
    var body: some View {
        VStack(spacing: 0) {
            headerView()
                .environment(\.colorScheme, .dark)

            GeometryReader {
                let size = $0.size

                ScrollView(.vertical) {
                    LazyVStack(spacing: 15, pinnedViews: [.sectionHeaders]) {
                        ForEach(currentWeek) { day in
                            let date = day.date
                            let isLast = currentWeek.last?.id == day.id

                            Section {
                                VStack(alignment: .leading, spacing: 15) {
                                    DummyTaskRow()
                                    DummyTaskRow()
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.leading, 70)
                                .padding(.top, -70)
                                .padding(.bottom, 10)
                                /// 70 negative padding , 40 content padding
                                .frame(minHeight: isLast ? size.height - 110 : nil, alignment: .top)
                            } header: {
                                VStack(spacing: 4) {
                                    Text(date.string("EEE"))

                                    Text(date.string("dd"))
                                        .font(.largeTitle.bold())
                                }
                                .frame(width: 55, height: 70)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    .scrollTargetLayout()
                }
                .contentMargins(.all, 20, for: .scrollContent)
                /// add vertically padding to the indicators
                .contentMargins(.vertical, 20, for: .scrollIndicators)
                .scrollPosition(id: .init(get: {
                    currentWeek.first(where: { $0.date.isSame(selectedDate) })?.id
                }, set: { newValue in
                    selectedDate = currentWeek.first(where: { $0.id == newValue })?.date
                }), anchor: .top)
                /// undo the negative padding effect
                .safeAreaPadding(.bottom, 70)
                .padding(.bottom, -70)
            }
            .background(.background)
            .clipShape(
                UnevenRoundedRectangle(topLeadingRadius: 30,
                                       bottomLeadingRadius: 0,
                                       bottomTrailingRadius: 0,
                                       topTrailingRadius: 30,
                                       style: .continuous)
            )
            .environment(\.colorScheme, .light)
            .ignoresSafeArea(.all, edges: .bottom)
        }
        .background(.black)
        .onAppear {
            guard selectedDate == nil else { return }
            selectedDate = currentWeek.first(where: { $0.date.isSame(.now) })?.date
        }
    }

    func headerView() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("This Week")
                    .font(.title.bold())
                    .fontWeight(.semibold)

                Spacer(minLength: 0)

                Button {} label: {
                    Image(.fox)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 35, height: 35)
                        .clipShape(.circle)
                }
            }

            /// Week View
            HStack(spacing: 0) {
                ForEach(currentWeek, id: \.self) { day in
                    let date = day.date
                    let isSameDate = date.isSame(selectedDate)
                    VStack(spacing: 6) {
                        Text(date.string("EEE"))
                            .font(.caption)

                        Text(date.string("dd"))
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(isSameDate ? .black : .white)
                            .frame(width: 38, height: 38)
                            .background {
                                if isSameDate {
                                    Circle()
                                        .fill(.white)
                                        .matchedGeometryEffect(id: "ACTIVEDATE", in: animation)
                                }
                            }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(.rect)
                    .onTapGesture {
                        withAnimation(.snappy(duration: 0.25, extraBounce: 0)) {
                            selectedDate = date
                        }
                    }
                }
            }
            .animation(.snappy(duration: 0.25, extraBounce: 0), value: selectedDate)
            .frame(height: 80)
            .padding(.vertical, 5)
            .offset(y: 5)

            HStack {
                Text(selectedDate?.string("MMM") ?? "")

                Spacer()

                Text(selectedDate?.string("YYYY") ?? "")
            }
            .font(.caption2)
        }
        .padding([.horizontal, .top], 15)
        .padding(.bottom, 10)
    }
}

struct DummyTaskRow: View {
    var isEmpty: Bool = false
    var body: some View {
        Group {
            if isEmpty {
                VStack(spacing: 8) {
                    Text("No task found today")

                    Text("Add new tasks.")
                        .font(.caption2)
                        .foregroundStyle(.gray)
                }
                .frame(height: 100)
                .frame(maxWidth: .infinity)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Circle()
                        .fill(.red)
                        .frame(width: 5, height: 5)

                    Text("Some Random Task")
                        .font(.system(size: 14))
                        .fontWeight(.semibold)

                    HStack {
                        Text("16:00 - 17:00")

                        Spacer(minLength: 0)

                        Text("Some Random Task")
                    }
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .padding(.top, 5)
                }
                .lineLimit(1)
                .padding(15)
            }
        }
        .background {
            RoundedRectangle(cornerRadius: 15)
                .fill(.background)
                .shadow(color: .black.opacity(0.35), radius: 1)
        }
    }
}

#Preview {
    CalendarWithMultipleHomeView()
}
