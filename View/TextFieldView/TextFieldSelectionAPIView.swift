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

                VStack(spacing: 15) {
                    HStack(spacing: 20) {
                        Button("Move After Hello World") {
                            if let range = text.range(of: "Hello") {
                                let endIndex = range.upperBound
                                selection = .init(insertionPoint: endIndex)
                            }
                        }

                        Button("Select Hello World") {
                            if let range = text.range(of: "Hello") {
                                selection = .init(range: range)
                            }
                        }
                    }

                    HStack(spacing: 20) {
                        Button("Move to First") {
                            selection = .init(insertionPoint: text.startIndex)
                        }

                        Button("Move to Last") {
                            selection = .init(insertionPoint: text.endIndex)
                        }
                    }

                    if let selectedTextRange, text[selectedTextRange] == "Hello" {
                        Button("Replace with Hi There") {
                            text.replaceSubrange(selectedTextRange, with: "Hi There")
                            // update selection text
                            let startIndex = selectedTextRange.lowerBound
                            let length = "Hi There".count
                            let endIndex = text.index(
                                startIndex,
                                offsetBy: length
                            )
                            let newRange: Range<String.Index> = .init(
                                uncheckedBounds: (startIndex, endIndex)
                            )
                            selection = .init(range: newRange)
                        }
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(15)
            .navigationTitle("Text Selection API")
            .background(.gray.opacity(0.1))
            .onChange(of: selection) { _, newValue in
                if let selection = newValue, !selection.isInsertion {
                    switch selection.indices {
                    case let .selection(range):
                        let selectedText = text[range]
                        print(selectedText)
                    default:
                        print("Others")
                    }
                }
            }
        }
    }

    var selectedTextRange: Range<String.Index>? {
        if let selection, !selection.isInsertion {
            switch selection.indices {
            case let .selection(range):
                return range
            default: return nil
            }
        }

        return nil
    }
}

#Preview {
    if #available(iOS 18.0, *) {
        TextFieldSelectionAPIView()
    } else {
        // Fallback on earlier versions
    }
}
