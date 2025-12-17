//
//  TruncatedTextEffect.swift
//  animation
//
//  Created on 12/16/25.

import SwiftUI

struct TruncatedTextEffectDemoView: View {
    @State private var isEnabled: Bool = false
    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                VStack {
                    Text(fullDummyDescription)
                        .truncationEffect(
                            length: 10,
                            isEnabled: isEnabled,
                            animation: .smooth(duration: 0.3, extraBounce: 0)
                        )
                        .onTapGesture {
                            isEnabled.toggle()
                        }
                }
                .padding(15)
            }
            .navigationTitle("Truncated Text Effect")
        }
    }
}

#Preview {
    TruncatedTextEffectDemoView()
}
