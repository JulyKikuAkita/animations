//
//  StackedScrollView.swift
//  animation

import SwiftUI

struct StackedScrollView: View {
    var body: some View {
        VStack {
            Spacer()
            
            BottomActionBar()
        }
        .padding(20)
    }
    
    @ViewBuilder
    func BottomActionBar() -> some View {
        HStack {
            Button(action: {}, label: {
                Image(systemName: "flashing.off.fill")
                    .font(.title3)
                    .frame(width: 35, height: 35)
            })
            .buttonStyle(.borderedProminent)
            .tint(.white.opacity(0.2))
            .buttonBorderShape(.circle)
            
            Spacer(minLength: 0)
            
            Button(action: {}, label: {
                Image(systemName: "camera.fill")
                    .font(.title3)
                    .frame(width: 35, height: 35)
            })
            .buttonStyle(.borderedProminent)
            .tint(.white.opacity(0.2))
            .buttonBorderShape(.circle)
        }
    }
}

#Preview {
    StackedScrollView()
}
