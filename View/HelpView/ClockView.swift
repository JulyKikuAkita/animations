//
//  ClockView.swift
//  animation
//
//  Created on 9/5/26.

import SwiftUI

struct ClockDemoView: View {
    var body: some View {
        VStack {
            ClockView()
        }
        .frame(width: 250, height: 250)
    }
}

struct ClockView: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(UIColor.systemGray5))

            /// Time
            ZStack {
                ForEach(0 ..< 12, id: \.self) {
                    let value = $0 * 2
                    let symbol = value == 0 || value == 6 ? "AM" : (value == 12 || value == 18 ? "PM" : "")
                    let isSymbol = !symbol.isEmpty
                    let rotation = Angle(degrees: Double($0 * 30))

                    HStack(alignment: .bottom, spacing: 0) {
                        Text("\(value % 12 == 0 ? 12 : value % 12)")
                        if isSymbol {
                            Text(symbol)
                                .textScale(.secondary)
                        }
                    }
                    .font(.system(
                        size: isSymbol ? 14 : 12,
                        weight: isSymbol ? .bold : .semibold
                    ))
                    .foregroundStyle(isSymbol ? Color.primary : .gray)
                    .rotationEffect(-rotation)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .rotationEffect(rotation)
                }
            }
            .overlay {
                VStack {
                    Image(systemName: "moon.fill")
                        .foregroundStyle(.indigo)
                    Spacer()
                    Image(systemName: "sun.max.fill")
                        .foregroundStyle(.yellow)
                }
                .padding(.vertical, 25)
            }
            .padding(20)

            /// Ticks
            ZStack {
                ForEach(0 ..< 60, id: \.self) {
                    let rotation = Angle(degrees: Double($0 * 6))

                    Capsule()
                        .fill(.gray)
                        .frame(width: 2, height: $0 % 5 == 0 ? 6 : 3)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .rotationEffect(rotation)
                }
            }
            .padding(5)
        }
    }
}

#Preview {
    ClockDemoView()
}
