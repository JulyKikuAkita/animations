//
//  HackerTextView.swift
//  animation

import SwiftUI
// https://www.youtube.com/watch?v=T5aUgq8GKnA&list=PLimqJDzPI-H97JcePxWNwBXJoGS-Ro3a-&index=106
// Todo :2:10
struct HackerTextView: View {
    /// Config
    var text: String
    var trigger: Bool
    var transition: ContentTransition = .interpolate
    var duration: CGFloat = 1.0
    var speed: CGFloat = 0.1
    
    /// View Properties
    @State private var animatedText = ""
    var body: some View {
        Text(animatedText)
            .fontDesign(.monospaced) // ensure same horizontal space for all characters
            .truncationMode(.tail)
            .contentTransition(transition)
            .onAppear {
                guard animatedText.isEmpty else { return }
            }
    }
    
    private func setRandomCharacters() {
        
    }
}

#Preview {
    HackerTextView(text: "HackerTextView", trigger: true)
}
