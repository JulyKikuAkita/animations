//
//  ScrollToHideHeaderInstagramView.swift
//  animation
//
import SwiftUI

struct ScrollToHideHeaderInstagramMock: View {
    var body: some View {
        ScrollView(.vertical) {
            LazyHStack(spacing: 12) {
                ForEach(1 ... 10, id: \.self) { _ in
                    Circle()
                        .fill(.fill)
                        .frame(width: 60, height: 60)
                        .padding(.bottom, 10)
                }
            }
            LazyVStack(spacing: 12) {
                ForEach(1 ... 10, id: \.self) { _ in
                    DummyCardView()
                }
            }
            .padding(10)
        }
        .scrollableHeader(dismissDistance: 60) {
            mockHeader()
        }
        .scrollIndicators(.hidden)
        .safeAreaPadding([.horizontal, .bottom], 15)
    }

    func mockHeader() -> some View {
        HStack {
            Button {} label: { Image(systemName: "plus") }
            Spacer(minLength: 0)
            Button {} label: { Image(systemName: "suit.heart") }
        }
        .overlay {
            Text("Mock Header")
                .fontWeight(.medium)
        }
        .font(.title3)
        .foregroundStyle(.primary)
        .padding(.horizontal, 15)
        .padding(.top, 10)
        .padding(.bottom, 15)
        .background(.background)
    }
}

#Preview {
    ScrollToHideHeaderInstagramMock()
}
