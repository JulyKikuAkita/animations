//
//  MessengerGradientEffectView.swift
//  animation

import SwiftUI

struct MessengerGradientEffectDemoView: View {
    var body: some View {
        NavigationStack {
            
        }
    }
}
// TODO: https://www.youtube.com/watch?v=U-9idyGKwgY&t=2s
/ /1:12
struct MessengerGradientEffectView: View {
    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 15) {
                ForEach(messages) { message in
                    Text(message.message)
                }
            }
        }
    }
}

#Preview {
    MessengerGradientEffectView()
}
