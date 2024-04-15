//
//  ParticleEffectsView.swift
//  animation
// https://www.youtube.com/watch?v=sLdQdOtpf7A at 2:01

import SwiftUI

struct ParticleEffectsView: View {
    @State private var isLiked: Bool = false
    var body: some View {
        CustomButton(systemImage: "suit.heart.fill", status: isLiked, activeTint: .pink, inActiveTint: .gray) {
            isLiked.toggle()
        }
    }
    
    @ViewBuilder
    func CustomButton(systemImage: String, status: Bool, activeTint: Color, inActiveTint: Color, onTap: @escaping () -> ()) -> some View {
        Button(action: onTap) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundColor(status ? activeTint : inActiveTint)
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .background {
                    Capsule()
                        .fill(status ? activeTint.opacity(0.25) : Color("ButtonColor"))
                }
        }
        
    }
}
