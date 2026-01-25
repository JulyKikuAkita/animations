//
//  DetailItemView.swift
//  animation
//
//  Created on 1/24/26.

import SwiftUI

struct DetailItemView: View {
    @Binding var config: ScrollHeroEffectConfig
    var photo: Photo
    var progress: CGFloat
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

                VStack(spacing: 12) {
                    Text(photo.author)
                        .font(.title2.bold())

                    Text(paragraph1)
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                        .kerning(0.5)
                }
                .compositingGroup()
                .opacity(opacity)
                .padding(.top, 10)
            }
            .padding(15)
        }
        .safeAreaInset(edge: .bottom) {
            bottomBar()
                .opacity(opacity)
        }
        .overlay(alignment: .topLeading) {
            /// close button
            Button {
                withAnimation(.interpolatingSpring(duration: 3)) {
                    config.expandDetailView = false
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.primary.secondary)
                    .padding(15)
                    .contentShape(.rect)
            }
            .opacity(opacity)
        }
    }

    /// only reveal paragraph when progress > 0.7
    var opacity: CGFloat {
        progress > 0.7 ? min((progress - 0.7) * 3.4, 1) : 0
    }

    func bottomBar() -> some View {
        HStack(spacing: 10) {
            Button {} label: {
                Text("+Fav")
                    .padding(.vertical, 5)
                    .frame(maxWidth: .infinity)
            }
            .tint(.red)

            Button {} label: {
                Text("Download")
                    .padding(.vertical, 5)
                    .frame(maxWidth: .infinity)
            }
            .tint(.blue)
        }
        .font(.callout)
        .fontWeight(.semibold)
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .padding(.horizontal, 15)
        .padding(.vertical, 10)
        .overlay(alignment: .top) {
            Divider()
        }
    }
}
