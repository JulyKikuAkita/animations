//
//  OffsetReader.swift
//  animation

import SwiftUI

struct OffsetReader: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat,
                       nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

extension View {
    @ViewBuilder
    func offsetX(completion: @escaping (CGFloat) -> ()) -> some View {
        self
            .overlay {
                GeometryReader {
                    let minX = $0.frame(in: .scrollView).minX
                    Color.clear
                        .preference(key: OffsetReader.self, value: minX)
                        .onPreferenceChange(OffsetReader.self, perform: { value in
                            completion(value)
                        })
                }
            }
    }
}

/// Card array extension
extension [Card] {
    func indexOf(_ card: Card) -> Int {
        return self.firstIndex(of: card) ?? 0
    }
}
