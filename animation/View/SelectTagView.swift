//
//  SelectTagView.swift
//  animation

import SwiftUI

struct SelectTagViewDemo: View {
    /// View properties
    /// Sample tags
    @State private var tags:[String] = [
        "Berserk", "Shingeki no Kyojin", "One Piece", "Chainsaw Man", "Tokyo Ghoul", "Solo Leveling", "Oyasumi Punpun", "Kimetsu no Yaiba", "One Punch-Man", "Boku no Hero Academia", "Jujutsu Kaisen", "Vagabond", "Fullmetal Alchemist", "Spy x Family", "Pandora Hearts"
    ]
    
    /// Selection
    @State private var selectedTags: [String] = []
    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    ForEach(selectedTags, id: \.self) { tag in
                    }
                }
                .padding(.horizontal, 15)
                .frame(height: 35)
                .padding(.vertical, 15)
            }
        }
        .preferredColorScheme(.light)
    }
    
    @ViewBuilder
    func TagView(_ tag: String, _ color: Color, _ icon: String) -> some View {
        HStack(spacing: 10) {
            Text(tag)
        }
    }
}


#Preview {
    SelectTagViewDemo()
}
