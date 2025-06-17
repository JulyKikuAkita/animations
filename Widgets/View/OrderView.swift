//
//  OrderView.swift
//  animation
//
//  Created on 6/16/25.

import AppIntents
import SwiftUI

enum OrderSteps: String {
    case step1 = "Confirming Product"
    case step2 = "Updating quantities"
    case step3 = "Confirming Order"
}

struct OrderView: View {
    var choice: LocalizedStringResource
    var count: Int
    var commision: Int

    var step: OrderSteps = .step1

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 15) {
                Image(.bitcoin)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Order Summary")

                    Group {
                        Text(choice)
                            .font(.title3)
                            .fontWeight(.semibold)

                        if step != .step1 {
                            Text("(\(count) x \(choice) selected)")
                        }

                        if step == .step3 {
                            HStack(spacing: 0) {
                                Text("(\(count) x \(commision)% commission)")
                            }
                        } else {
                            HStack(spacing: 8) {
                                Group {
                                    if step == .step1 {
                                        Text("x \(count)")
                                    }

                                    if step == .step2 {
                                        Text("(\(commision) selected)")
                                    }
                                }

                                Spacer(minLength: 0)

                                actionButton(false)
                                actionButton(true)
                            }
                            .font(.title3)
                            .fontWeight(.semibold)
                        }
                    }
                    .foregroundStyle(.white)
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                }
                .foregroundStyle(.white)
            }
        }
        .padding(15)
        .background {
            LinearGradient(colors: [.yellow, .orange],
                           startPoint: .leading,
                           endPoint: .trailing)
                .clipShape(.containerRelative)
        }
    }

    func actionButton(_ isIncrement: Bool) -> some View {
        Button(intent: OrderActionIntent(
            isUpdaingPercentage: step == .step1,
            isIncremental: isIncrement
        )) {
            Image(systemName: isIncrement ? "plus" : "minus")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(maxWidth: 100)
                .frame(height: 40)
                .background {
                    UnevenRoundedRectangle(
                        topLeadingRadius: isIncrement ? 10 : 30,
                        bottomLeadingRadius: isIncrement ? 10 : 30,
                        bottomTrailingRadius: isIncrement ? 30 : 10,
                        topTrailingRadius: isIncrement ? 30 : 10,
                        style: .continuous
                    )
                    .fill(.ultraThinMaterial)
                }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    OrderView(choice: "Doge", count: 100, commision: 5)
}
