//
//  TextFieldSelectionAPIView.swift
//  animation


import SwiftUI

@available(iOS 18.0, *)
struct TextFieldSelectionAPIView: View {
    /// View properties
    @State private var text: String = ""
    @State private var selection: TextSelection? = .init(insertionPoint: "".startIndex) // fix selection not updated Swift bug
    var body: some View {
        NavigationStack {
            VStack {
                TextEditor(text: $text, selection: $selection)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 15)
                    .frame(height: 150)
                    .background(.background, in: .rect(cornerRadius: 10))
                
                Spacer(minLength: 0)
            }
            .padding(15)
            .navigationTitle("Text Selection API")
            .background(.gray.opacity(0.1))
            .onChange(of: selection) { oldValue, newValue in
                if let selection = newValue, !selection.isInsertion {
                    switch selection.indices {
                    case .selection(let range):
                        let selectedText = text[range]
                        print(selectedText)
                    default:
                        print("Others")
                    }
                
                }
            }
        }
    }
}

#Preview {
    if #available(iOS 18.0, *) {
        TextFieldSelectionAPIView()
    } else {
        // Fallback on earlier versions
    }
}
