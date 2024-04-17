//
//  ParticleEffectsView.swift
//  animation
// https://www.youtube.com/watch?v=sLdQdOtpf7A

import SwiftUI

struct ParticleEffectsView: View {
    @State private var heart: Bool = true
    @State private var star: Bool = true
    @State private var doge: Bool = true


    var body: some View {
        VStack{
            HStack(spacing: 20){
                CustomButton(systemImage: "suit.heart.fill", status: heart, activeTint: .pink, inActiveTint: .gray) {
                    heart.toggle()
                }
                
                CustomButton(systemImage: "star.fill", status: star, activeTint: .yellow, inActiveTint: .yellow) {
                    star.toggle()
                }
                
                CustomButton(systemImage: "pawprint", status: doge, activeTint: .blue, inActiveTint: .gray) {
                    doge.toggle()
                }
            }
        }
        
    }
    
    @ViewBuilder
    func CustomButton(systemImage: String, status: Bool, activeTint: Color, inActiveTint: Color, onTap: @escaping () -> ()) -> some View {
        Button(action: onTap) {
            Image(systemName: systemImage)
                .font(.title2)
                .particleEffect(
                    systemImage: systemImage,
                    font: .title2, 
                    status: status,
                    activeTint: activeTint,
                    inActiveTint: inActiveTint
                )
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
#Preview {
    ParticleEffectsView()
}
