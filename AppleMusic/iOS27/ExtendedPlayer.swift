//
//  ExtendedPlayer.swift
//  animation
//
//  Created on 9/9/26.

import SwiftUI

@available(iOS 26.0, *)
struct ExtendedPlayer: View {
    var size: CGSize
    var safeArea: EdgeInsets
    var namespace: Namespace.ID
    @Binding var config: PlayerContainerConfig
    var dismissAction: () -> Void = {}
    @State private var fadeIn: Bool = false
    var body: some View {
        VStack(spacing: 15) {
            Capsule()
                .fill(.white.secondary)
                .frame(width: 50, height: 4)
                /// optional fadeout effect
                .animation(config.animation.speed(2)) {
                    $0.opacity(config.expandPlayer ? 1 : 0)
                }
                .opacity(fadeIn ? 1 : 0)

            Spacer(minLength: 0)

            let artworkSize: CGFloat = size.width - 120
            RoundedRectangle(cornerRadius: 5)
                .overlay {
                    Image(.foxOutline)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
                .clipShape(.rect(cornerRadius: 10))
                .matchedGeometryEffect(id: "Artwork", in: namespace)
                .frame(width: artworkSize, height: artworkSize)
                .onTapGesture {
                    dismissAction()
                }

            Spacer(minLength: 0)

            dummyControls()
                .animation(config.animation.speed(2)) {
                    $0.opacity(config.expandPlayer ? 1 : 0)
                }
                .opacity(fadeIn ? 1 : 0)
        }
        .padding(.top, safeArea.top)
        .padding(.bottom, safeArea.bottom + 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            LinearGradient(colors: [.gray, .brown], startPoint: .top, endPoint: .bottom)
        }
        .onAppear {
            /// optional fadeIn effect
            withAnimation(config.animation.delay(0.1)) {
                fadeIn = true
            }
        }
    }

    private func dummyControls() -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 15) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Fox Outline")
                        .font(.title.bold())
                        .foregroundStyle(.white)

                    Text("Fox. Co., LTD.")
                        .fontWeight(.medium)
                        .foregroundStyle(.white.secondary)
                }

                Spacer(minLength: 0)

                Button {} label: {
                    Image(systemName: "star.circle.fill")
                        .font(.title)
                }
                .foregroundStyle(.white, .white.tertiary)

                Button {} label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.title)
                }
                .foregroundStyle(.white, .white.tertiary)
            }

            VStack(spacing: 2) {
                Slider(value: .constant(0.5))
                    .sliderThumbVisibility(.hidden)
                    .tint(.white)

                HStack {
                    Text("0:00")
                    Spacer(minLength: 0)
                    Text("4:31")
                }
                .foregroundStyle(.white)
                .font(.caption)
            }
            .padding(.top, 10)

            HStack {
                Button {} label: {
                    Image(systemName: "backward.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .contentShape(.rect)
                }

                Button {} label: {
                    Image(systemName: "play.fill")
                        .font(.system(size: 50))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .contentShape(.rect)
                }

                Button {} label: {
                    Image(systemName: "forward.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .contentShape(.rect)
                }
            }
            .foregroundStyle(.white)
            .font(.largeTitle)
            .frame(maxHeight: 100)

            VStack(spacing: 2) {
                HStack(spacing: 10) {
                    Image(systemName: "speaker.fill")
                        .foregroundStyle(.white.secondary)

                    Slider(value: .constant(1))
                        .sliderThumbVisibility(.hidden)
                        .tint(.white)

                    Image(systemName: "speaker.wave.3.fill")
                        .foregroundStyle(.white.secondary)
                }

                HStack(spacing: 10) {
                    Image(systemName: "quote.bubble")
                        .frame(maxWidth: .infinity)

                    Image(systemName: "airpods.gen4")
                        .frame(maxWidth: .infinity)

                    Image(systemName: "list.dash")
                        .frame(maxWidth: .infinity)
                }
                .font(.title3)
                .foregroundStyle(.white)
                .padding(.top, 10)
            }
            .padding(.vertical, 10)
        }
        .padding(.horizontal, 30)
        .compositingGroup()
    }
}
