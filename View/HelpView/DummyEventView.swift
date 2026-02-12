//
//  DummyEventView.swift
//  animation
//
//  Created on 5/31/25.

import SwiftUI

@available(iOS 26.0, *)
struct DummyEventViews: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 15) {
                    headerView()
                    dummyPopularEvents()

                    VStack(alignment: .leading, spacing: 15) {
                        Text("Nearby Events")
                            .font(.title3)
                            .fontWeight(.semibold)

                        ForEach(sampleEvents.indices, id: \.self) { index in
                            eventsOnDay(index)
                        }
                    }
                }
                .padding(15)
            }
        }
    }

    func headerView() -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Image(systemName: "swift")
                .font(.system(size: 40))
                .foregroundStyle(.orange)
                .padding(15)
                .background(.orange.tertiary, in: .circle)
                .padding(.bottom, 5)

            Text("Swift/Taylor")
                .font(.title.bold())

            Text("**125** Events  **15.6k** Subscribers")
                .font(.callout)

            Text(dummyDescription)
                .font(.callout)
                .lineLimit(5)

            Button("Subscribe") {}
                .buttonStyle(.glassProminent)
                .buttonSizing(.flexible)
                .frame(maxWidth: 140)
                .tint(.orange)
        }
        .padding(.bottom, 15)
        .overlay(alignment: .bottom) {
            Divider()
                .padding(.horizontal, -15)
        }
    }

    func dummyPopularEvents() -> some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Popular Events")
                    .font(.title3)
                    .fontWeight(.semibold)
                Image(systemName: "chevron.right")
                    .foregroundStyle(.gray)
            }

            RoundedRectangle(cornerRadius: 30)
                .foregroundStyle(.gray.tertiary)
                .frame(height: 220)
        }
        .padding(.top, 10)
        .padding(.bottom, 20)
        .overlay(alignment: .bottom) {
            Divider()
                .padding(.horizontal, -15)
        }
    }

    var sampleEvents: [String] {
        ["Tomorrow / Saturday", "Feb 14 / Sunday"]
    }

    func eventsOnDay(_ index: Int) -> some View {
        let title: String = sampleEvents[index]

        return VStack(alignment: .leading, spacing: 15) {
            Text(title)

            ForEach(1 ... 5, id: \.self) { _ in
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 10)
                        .frame(width: 100, height: 100)

                    VStack(alignment: .leading, spacing: 10) {
                        RoundedRectangle(cornerRadius: 5)
                            .frame(width: 250, height: 25)

                        RoundedRectangle(cornerRadius: 5)
                            .frame(height: 25)

                        RoundedRectangle(cornerRadius: 5)
                            .frame(width: 150, height: 25)
                    }
                }
                .foregroundStyle(.gray.tertiary)

                Divider()
            }
        }
    }
}

@available(iOS 26.0, *)
#Preview {
    DummyEventViews()
}
