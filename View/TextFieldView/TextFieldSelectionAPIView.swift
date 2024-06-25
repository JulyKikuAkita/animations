//
//  TextFieldSelectionAPIView.swift
//  animation


import SwiftUI

@available(iOS 18.0, *)
struct TextFieldSelectionAPIView: View {
    /// View properties
    @State private var text: String = ""
    @State private var selection: TextSelection?
    var body: some View {
        NavigationStack {
            VStack {
                TextEditor(text: $text, selection: $selection)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 15)
                    .frame(height: 150)
                    .background(.background, in: .rect(cornerRadius: 150))
                
                Spacer(minLength: 0)
            }
            .padding(15)
            .navigationTitle("Text Selection API")
            .background(.gray.opacity(0.1))
            .onChange(of: selection) { oldValue, newValue in
                print(newValue)
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
