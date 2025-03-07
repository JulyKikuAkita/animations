//
//  StackedScrollView.swift
//  animation

import SwiftUI

struct StackedScrollDemoView: View {
    var body: some View {
        ZStack {
            GeometryReader { _ in
                Image(.IMG_0215)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()

                StackedScrollView()
            }
        }
        .environment(\.colorScheme, .dark)
    }
}

struct StackedScrollView: View {
    var body: some View {
        VStack {
            StackedCards(
                items: stackCards,
                stackedDisplayCount: 1,
                opacityDisplayCount: 0,
                itemHeight: 70) { item in
                    StackCardView(item)
            }
            .padding(.bottom, 20)

            BottomActionBar()
        }
        .padding(20)
    }

    @ViewBuilder
    func StackCardView(_ item: Profile) -> some View {
        if item.username.isEmpty {
            Rectangle()
                .fill(.clear)

        } else {
            HStack(spacing: 12) {
                Image(item.profilePicture)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 4, content: {
                    Text(item.username)
                        .font(.callout)
                        .fontWeight(.bold)

                    Text(item.lastMsg)
                        .font(.caption)
                        .lineLimit(1)
                })
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(10)
            .frame(maxHeight: .infinity)
            .background(.ultraThinMaterial)
            .clipShape(.rect(cornerRadius: 20))
        }
    }

    @ViewBuilder
    func BottomActionBar() -> some View {
        HStack {
            Button(action: {}, label: {
                Image(systemName: "flashlight.off.fill")
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
    StackedScrollDemoView()
}
