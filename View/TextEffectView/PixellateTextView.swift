//
//  PixellateTextView.swift
//  animation

import SwiftUI

@available(iOS 18.0, *)
struct PixellateTextView: View {
    @State private var reveal: Bool = false
    @State private var type: RevealRenderer.RevealType = .blur
    @State private var revealProgress: CGFloat = 0

    var body: some View {
        // NavigationStack introduce buggy behavior with text effect at the time of writing
        VStack {
            Picker("", selection: $type) {
                ForEach(RevealRenderer.RevealType.allCases, id: \.rawValue) { type in
                    Text(type.rawValue)
                        .tag(type)
                }
            }
            .pickerStyle(.segmented)

            let apiKey = Text("qazwsx123edcrfv")
                .fontWeight(.semibold)
                .foregroundStyle(Color.primary)
                .customAttribute(APIKeyAttribute())

             Text("Your API Key is \(apiKey).\n Don't share it.")
                .font(.largeTitle)
                .fontDesign(.rounded)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .foregroundColor(.gray)
                .textRenderer(
                    RevealRenderer(type: type, progress: revealProgress)
                ) // count as a new line
                .padding(.vertical, 20)

            Button {
                reveal.toggle()
                withAnimation(.smooth) {
                    revealProgress = reveal ? 1: 0
                }
            } label: {
                Text(reveal ? "Hide Key" : "Reveal Key")
                    .padding(.horizontal, 25)
                    .padding(.vertical,4)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .tint(.black)

            Spacer(minLength: 0)

        }
        .padding(15)
        .navigationTitle("Text Rendered")
    }
}

#Preview {
    if #available(iOS 18.0, *) {
        PixellateTextView()
    } else {
        // Fallback on earlier versions
    }
}

/// Text Attribute: distinguish text that has to be rendered differently
struct APIKeyAttribute: TextAttribute {

}
