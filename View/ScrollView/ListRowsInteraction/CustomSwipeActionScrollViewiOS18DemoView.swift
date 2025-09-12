//
//  CustomSwipeActionScrollViewiOS18DemoView.swift
//  animation

import SwiftUI

struct CustomSwipeActionScrollViewiOS18DemoView: View {
    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                VStack {
                    ForEach(1 ... 100, id: \.self) { _ in
                        Rectangle()
                            .fill(.black.gradient)
                            .frame(height: 50)
                            .swipeActions {
                                SwipeActionModel(
                                    symbolImage: "square.and.arrow.up.fill",
                                    tint: .white,
                                    background: .blue
                                ) { resetPosion in
                                    resetPosion.toggle()
                                }

                                SwipeActionModel(
                                    symbolImage: "square.and.arrow.down.fill",
                                    tint: .white,
                                    background: .purple
                                ) { _ in
                                }

                                SwipeActionModel(
                                    symbolImage: "trash.fill",
                                    tint: .white,
                                    background: .red
                                ) { _ in
                                }
                            }
                    }
                }
                .padding(15)
            }
            .navigationTitle("Custom Swipe Actions")
        }
    }
}

#Preview {
    CustomSwipeActionScrollViewiOS18DemoView()
}
