//
//  DetailItemView.swift
//  animation
//
//  Created on 1/24/26.

import SwiftUI

struct DetailItemView: View {
    @Binding var config: ScrollHeroEffectConfig
    var photo: Photo
    var namespace: Namespace.ID
    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 15) {
                Image(photo.assetName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 160, height: 220)
                    .clipShape(.rect(cornerRadius: 20))
                    .matchedGeometryEffect(id: photo.imageID, in: namespace)
                    .onTapGesture {
                        withAnimation(.interpolatingSpring(duration: 3)) {
                            config.expandDetailView = false
                        }
                    }
            }
            .padding(15)
        }
    }
}
