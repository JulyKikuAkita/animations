//
//  DummyViews.swift
//  animation
//
//  Created on 5/31/25.

import SwiftUI

struct DummyViews: View {
    var body: some View {
        DummyStatusBar()
        List {
            DummySection(title: "Dymmy Section")

            Section {
                DummyMenuView()
            }
            Section {
                DummyTaskRow()
            }
            Section {
                DummyCardView()
                DummyCardStyleView()
            }
            Section {
                DummyMessagesView()
            }
            Section {
                DummyRectangles(color: .indigo, count: 3)
            }
            Section {
                DummyGridView(rowCount: 2, gridCount: 8, tint: .orange)
                DummyWidgetGridView()
            }
        }
    }
}

struct DummyRectangles: View {
    let color: Color
    let count: Int
    var body: some View {
        LazyVStack(spacing: 12) {
            ForEach(0 ..< count, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.gradient)
                    .frame(height: 45)
            }
        }
        .padding(15)
    }
}

struct DummyMessagesView: View {
    var count: Int = 2
    var body: some View {
        ForEach(0 ..< count, id: \.self) { _ in
            HStack(spacing: 12) {
                Circle()
                    .frame(width: 55, height: 55)

                VStack(alignment: .leading, spacing: 6, content: {
                    Rectangle()
                        .frame(width: 140, height: 8)

                    Rectangle()
                        .frame(height: 8)

                    Rectangle()
                        .frame(width: 80, height: 8)
                })
            }
            .foregroundStyle(.gray.opacity(0.4))
            .padding(.horizontal, 15)
        }
    }
}

struct DummySection: View {
    let title: String
    let isLong: Bool = false
    var body: some View {
        VStack(alignment: .leading, spacing: 8, content: {
            Text(title)
                .font(.title.bold())

            Text(dummyDescription)
                .multilineTextAlignment(.leading)
                .kerning(1.2)
        })
        .frame(maxWidth: .infinity, alignment: .leading)
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

struct DummyCardView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            RoundedRectangle(cornerRadius: 6)
                .frame(minHeight: 220)

            HStack(spacing: 10) {
                Circle()
                    .frame(width: 45, height: 45)

                VStack(alignment: .leading, spacing: 4) {
                    Rectangle()
                        .frame(height: 10)

                    HStack(spacing: 10) {
                        Rectangle()
                            .frame(width: 100)

                        Rectangle()
                            .frame(width: 80)

                        Rectangle()
                            .frame(width: 60)
                    }
                    .frame(height: 10)
                }
            }
        }
        .foregroundStyle(.tertiary)
    }
}

struct DummyCardStyleView: View {
    var body: some View {
        HStack(spacing: 15) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Cookies")
                    .font(.title.bold())

                Text(dummyDescription)
                    .fixedSize(horizontal: false, vertical: true)
                    .font(.callout)
                    .lineLimit(2)
                    .foregroundStyle(.gray)

                Text("$15.98")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            RoundedRectangle(cornerRadius: 20)
                .fill(.gray.opacity(0.1))
                .frame(width: 100, height: 100)
        }
        .redacted(reason: .placeholder)
        .padding(10)
        .padding(.leading, 10)
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 30))
        .padding(.horizontal, 15)
    }
}

struct DummyMenuView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            DummyMenuRow(image: "paperplane", title: "Send", lineLimit: 2)
            DummyMenuRow(
                image: "arrow.trianglehead.2.counterclockwise",
                title: "Swap",
                lineLimit: 2
            )
            DummyMenuRow(image: "arrow.down", title: "Receive", lineLimit: 2)
        }
        .padding(.horizontal, 5)
    }
}

struct DummyMenuRow: View {
    var image: String
    var title: String
    var lineLimit: Int = 2
    var body: some View {
        HStack(spacing: 18) {
            Image(systemName: image)
                .font(.title2)
                .frame(width: 45, height: 45)
                .background(.background, in: .circle)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3)
                    .foregroundStyle(.primary)
                    .fontWeight(.semibold)

                Text(dummyDescription)
                    .font(.callout)
                    .foregroundStyle(.gray)
                    .lineLimit(lineLimit)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(4)
        .contentShape(.rect)
    }
}

struct DummyGridView: View {
    var rowCount: Int = 2
    var gridCount: Int = 20
    var tint: Color = .red
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(), count: rowCount)) {
            ForEach(1 ... gridCount, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 25)
                    .fill(tint.gradient)
                    .frame(height: 160)
                    .overlay(alignment: .topLeading) {
                        VStack(alignment: .leading, spacing: 6) {
                            Circle()
                                .fill(.bar)
                                .frame(width: 45, height: 45)
                                .padding(.bottom, 5)

                            Capsule()
                                .fill(.bar).frame(width: 100, height: 5)

                            Capsule()
                                .fill(.bar).frame(width: 80, height: 5)

                            Capsule()
                                .fill(.bar).frame(width: 40, height: 5)
                        }
                        .padding(15)
                    }
            }
        }
        .padding(15)
    }
}

// Mock widget grids
struct DummyWidgetGridView: View {
    var totalItems: Int = 12
    var backgroundColor: Color = .black
    var showFrame: Bool = true
    var body: some View {
        VStack(spacing: 15) {
            HStack(spacing: 15) {
                RoundedRectangle(cornerRadius: 20)
                RoundedRectangle(cornerRadius: 20)
            }
            .frame(height: 130)

            LazyVGrid(columns: Array(repeating: GridItem(spacing: 15), count: 4),
                      spacing: 15)
            {
                ForEach(1 ... totalItems, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 10)
                        .frame(height: 55)
                }
            }
        }
        .padding(20)
        .padding(.top, 20)
        .foregroundStyle(backgroundColor.opacity(0.1))
        .overlay {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(backgroundColor.opacity(0.06))

                RoundedRectangle(cornerRadius: 20)
                    .stroke(.gray.opacity(0.5), lineWidth: 1.5)
            }
            .opacity(showFrame ? 1 : 0)
        }
    }
}

/// Mock status bar
struct DummyStatusBar: View {
    var body: some View {
        var time = "7:22"
        HStack(spacing: 4) {
            Text(time)
                .fontWeight(.bold)
            Spacer()

            Image(systemName: "cellularbars")
            Image(systemName: "wifi")
            Image(systemName: "battery.50percent")
        }
        .font(.caption2)
        .padding(.horizontal, 20)
        .padding(.top, 15)
    }
}

#Preview {
    DummyViews()
}
