//
//  SearchView.swift
//  demoApp

import SwiftUI

struct SearchView: View {
    @State private var activeID: String? = dummyBooks.first?.id
    @State private var scrollPosition: ScrollPosition = .init(idType: String.self)
    @State private var isAnyBookScrolled: Bool = false
    var body: some View {
        GeometryReader { geometry in
            ScrollView(.horizontal) {
                HStack(spacing: 4) {
                    ForEach(dummyBooks) { book in
                        BookCardView(book: book, size: geometry.size){ isScrolled in
                            isAnyBookScrolled = isScrolled
                        }
                        .frame(width: geometry.size.width - 30)
                        .zIndex(activeID == book.id ? 1000 : 1) /// mark current active card to the top
                    }
                }
                .scrollTargetLayout()
            }
            .safeAreaPadding(15)
            .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
            .scrollPosition($scrollPosition)
            .scrollDisabled(isAnyBookScrolled)
            .onChange(of: scrollPosition.viewID(type: String.self)) { oldValue, newValue in
                activeID = newValue
            }
            .scrollIndicators(.hidden)
        }
    }
}

#Preview {
    SearchView()
}
