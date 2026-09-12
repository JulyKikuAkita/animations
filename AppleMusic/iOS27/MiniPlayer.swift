//
//  MiniPlayer.swift
//  animation
//
//  Created on 9/9/26.

import SwiftUI

struct MiniPlayer: View {
    var namespace: Namespace.ID
    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 5)
                .overlay {
                    Image(.fox)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
                .clipShape(.rect(cornerRadius: 5))
                .matchedGeometryEffect(id: "Artwork", in: namespace)
                .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text("Fox Outline")
                    .font(.callout)

                Text("Fox Co., Ltd.")
                    .font(.caption)
            }

            Spacer(minLength: 0)

            Button {} label: {
                Image(systemName: "play.fill")
                    .font(.title3)
                    .padding(.horizontal, 5)
            }
        }
        .foregroundStyle(.primary)
        .padding(.leading, 20)
        .padding(.trailing, 15)
    }
}
