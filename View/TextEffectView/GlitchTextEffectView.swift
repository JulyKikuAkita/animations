//
//  GlitchTextEffectView.swift
//  animation

import SwiftUI

struct GlitchTextEffectDemoView: View {
    /// View properties
    @State private var trigger: Bool = false
    var body: some View {
        VStack {
            GlitchTextEffectView(text: "Made in Abyss", trigger: trigger)
                .font(.system(size: 60, weight: .semibold))
        }
        .padding()
    }
}

struct GlitchTextEffectView: View {
    var text: String
    /// Config
    var trigger: Bool
    var body: some View {
        KeyframeAnimator(initialValue: false, trigger: trigger) { value in
            TextView()
            
        } keyframes: { _ in
            // TODO: 1:30 https://www.youtube.com/watch?v=8CedpKnYQBY&list=PLimqJDzPI-H97JcePxWNwBXJoGS-Ro3a-&index=112
        }
    }
    
    @ViewBuilder
    func TextView() -> some View {
        Text(text)
    }
}

#Preview {
    GlitchTextEffectDemoView()
}
