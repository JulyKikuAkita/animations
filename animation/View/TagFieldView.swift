//
//  TagFieldView.swift
//  animation

// wip
// https://www.youtube.com/watch?v=6aw1KaUg4MY&list=PLimqJDzPI-H97JcePxWNwBXJoGS-Ro3a-&index=37
// 4:05
import SwiftUI

struct TagFieldDemoView: View {
    /// View properties
    @State private var tags:[Tag] = []
    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                VStack {
                    TagField(tags: $tags)
                }
                .padding()
            }
            .navigationTitle("Tag Field")
        }
    }
}

struct TagField: View {
    @Binding var tags: [Tag]
    var body: some View {
        HStack {
            ForEach($tags){ $tag in
                TagView(tag: $tag, allTags: $tags)
                    .onChange(of: tag.value) { newValue, oldValue in
                        if newValue.last == "," {
                            /// removing last comma
                            tag.value.removeLast()
                        }
                    }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 15)
        .background(.bar, in: .rect(cornerRadius: 12))
        .onAppear(perform: {
            /// Initialing tag view
            if tags.isEmpty {
                tags.append(.init(value: "", isInitial: true))
            }
        })
    }
}

/// Tag view
fileprivate struct TagView: View {
    @Binding var tag: Tag
    @Binding var allTags: [Tag]
    @FocusState private var isFocused: Bool
    /// View properties
    @Environment(\.colorScheme) private var colorScheme
    var body: some View {
        TextField("Tag", text: $tag.value)
            .focused($isFocused)
            .padding(.vertical, 10)
            .padding(.horizontal, isFocused || tag.value.isEmpty ? 0 : 10)
            .background((colorScheme == .dark ? Color.black : Color.white).opacity(isFocused || tag.value.isEmpty ? 0 : 1), in: .rect(cornerRadius: 12))
            .disabled(tag.isInitial)
            .overlay {
                if tag.isInitial {
                    Rectangle()
                        .fill(.clear)
                        .contentShape(.rect)
                        .onTapGesture {
                            tag.isInitial = false
                            isFocused = true
                        }
                }
            }
    }
}

#Preview {
    TagFieldDemoView()
}
