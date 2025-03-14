//
//  SelectTagView.swift
//  animation

import SwiftUI

struct SelectTagViewDemo: View {
    /// View properties
    /// Sample tags
    @State private var tags: [String] = [
        "Berserk", "Hunter", "One Piece", "Chainsaw Man", "Tokyo Ghoul", "Solo Leveling", "Naruto", "Monster", "Vagabond", "SpyFamily", "One Punch-Man", "Hero Academia", "Jujutsu Kaisen", "Fullmetal Alchemist", "Pandora Hearts", "Bleach", "Gantz", "Frieren",
    ]

    /// Selection
    @State private var selectedTags: [String] = []
    /// Adding matched geometry effect
    @Namespace private var animation
    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    ForEach(selectedTags, id: \.self) { tag in
                        TagView(tag, .pink, "checkmark")
                            .matchedGeometryEffect(id: tag, in: animation)
                            .onTapGesture {
                                withAnimation(.snappy) {
                                    selectedTags.removeAll(where: { $0 == tag })
                                }
                            }
                    }
                }
                .padding(.horizontal, 15)
                .frame(height: 35)
                .padding(.vertical, 15)
            }
            .overlay(content: {
                if selectedTags.isEmpty {
                    Text("Select more than 3 Tags")
                        .font(.callout)
                        .foregroundStyle(.gray)
                }
            })
            .background(.white)
            .zIndex(1)

            ScrollView(.vertical) {
                TagLayout(spacing: 10) {
                    ForEach(tags.filter { !selectedTags.contains($0) }, id: \.self) { tag in
                        TagView(tag, .blue, "plus")
                            .matchedGeometryEffect(id: tag, in: animation)
                            .onTapGesture {
                                /// Adding to Selected Tag list
                                withAnimation(.snappy) {
                                    selectedTags.insert(tag, at: 0)
                                }
                            }
                    }
                }
                .padding(15)
            }
            .scrollClipDisabled(true)
            .scrollIndicators(.hidden)
            .background(.black.opacity(0.05))
            .zIndex(0)

            ZStack {
                Button(action: {
                    selectedTags.removeAll()
                }, label: {
                    Text("Reset")
                        .fontWeight(.semibold)
                        .padding(.vertical, 15)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .background {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.pink.gradient)
                        }
                })
                /// Disabling until 3 more tags selected
                .disabled(selectedTags.count <= 3)
                .opacity(selectedTags.count <= 3 ? 0.5 : 1)
                .padding()
            }
            .background(.white)
            .zIndex(2)
        }
        .preferredColorScheme(.light)
    }

    /// Tag view
    @ViewBuilder
    func TagView(_ tag: String, _ color: Color, _ icon: String) -> some View {
        HStack(spacing: 10) {
            Text(tag)
                .font(.callout)
                .fontWeight(.semibold)

            Image(systemName: icon)
        }
        .frame(height: 35)
        .foregroundStyle(.white)
        .padding(.horizontal, 15)
        .background {
            Capsule()
                .fill(color)
        }
    }
}

#Preview {
    SelectTagViewDemo()
}
