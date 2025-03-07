//
//  ExpandableMusicPlayerView.swift
//  animation

import SwiftUI

struct ExpandableMusicPlayerView: View {
    @Binding var show: Bool

    /// View Properties
    @State private var expandPlayer: Bool = false
    @State private var offsetY: CGFloat = 0
    @State private var mainWindow: UIWindow?
    @State private var windowProgress: CGFloat = 0
    @Namespace private var animation
    var body: some View {
        GeometryReader {
            let size = $0.size
            let safeArea = $0.safeAreaInsets

            ZStack(alignment: .top) {
                ZStack {
                    /// miniplayer background
                    Rectangle()
                        .fill(.orange.gradient)

                    /// background
                    Rectangle()
                        .fill(
                            .linearGradient(
                                colors: [.pink, .orange],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .opacity(expandPlayer ? 1 : 0)
                }
                .clipShape(.rect(cornerRadius: expandPlayer ? 45 : 15))
                .frame(height: expandPlayer ? nil : 55)
                .shadow(color: .primary.opacity(0.06), radius: 5, x: 5, y: 5)
                .shadow(color: .primary.opacity(0.05), radius: 5, x: -5, y: -5)

                MiniPlayer()
                    .opacity(expandPlayer ? 0 : 1)

                ExpandedPlayer(size, safeArea)
                    .opacity(expandPlayer ? 1 : 0)

            }
            .frame(height: expandPlayer ? nil : 55, alignment: .top)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding(.bottom, expandPlayer ? 0 : safeArea.bottom + 55)
            .padding(.horizontal, expandPlayer ? 0 : 15)
            .offset(y: offsetY)
            .gesture(
                PanGesture { value in
                    guard expandPlayer else { return }
                    let translation = max(value.translation.height, 0)
                    offsetY = translation
                    windowProgress = max(min(translation / size.height, 1), 0) * 0.1

                    resizeWindow(0.1 - windowProgress)
                } onEnd: { value  in
                    guard expandPlayer else { return }
                    let translation = max(value.translation.height, 0)
                    let velocity = value.velocity.height / 5

                    withAnimation(.smooth(duration: 0.3, extraBounce: 0)) {
                        if (translation + velocity) > (size.height * 0.5) {
                            expandPlayer = false

                            /// reset resize Window to identity
                            resetResizeWindow()
                        } else { /// reset resize Window to 0.1
                            UIView.animate(withDuration: 0.3) {
                                resizeWindow(0.1)
                            }
                        }
                    }
                    offsetY = 0
                }
            ) /// draggable on image area
            .ignoresSafeArea()

         }
        .onAppear {
            if let window = (
                UIApplication.shared.connectedScenes.first as? UIWindowScene
            )?.keyWindow, mainWindow == nil {
                mainWindow = window
            }
        }


    }

    @ViewBuilder
    func MiniPlayer() -> some View {
        HStack(spacing: 12) {
            ZStack {
                if !expandPlayer {
                    Image(.fox)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipShape(.rect(cornerRadius: 10))
                        .matchedGeometryEffect(id: "Artwork", in: animation)
                }

            }
            .frame(width: 45, height: 45)

            Text("Fox")

            Spacer(minLength: 0)

            Group {
                Button("", systemImage: "play.fill") {

                }

                Button("", systemImage: "forward.fill") {

                }
            }
            .font(.title3)
            .foregroundStyle(.primary)
        }
        .padding(.horizontal, 10)
        .frame(height: 55)
        .contentShape(.rect)
        .onTapGesture {
            withAnimation(.smooth(duration: 0.3, extraBounce: 0)) {
                expandPlayer = true
            }

            /// reset resize Window to 0.1
            UIView.animate(withDuration: 0.3) {
                resizeWindow(0.1)
            }
        }
    }

    @ViewBuilder
    func ExpandedPlayer(_ size: CGSize, _ safeArea: EdgeInsets) -> some View {
        VStack(spacing: 12) {
            Capsule()
                .fill(.white.secondary)
                .frame(width: 35, height: 5)
                .offset(y: -10)

            /// Sample Player View
            HStack(spacing: 12) {
                ZStack {
                    if expandPlayer {
                        Image(.fox)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .clipShape(.rect(cornerRadius: 10))
                            .matchedGeometryEffect(id: "Artwork", in: animation)
                            .transition(.offset(y: 1))
                    }

                }
               .frame(width: 80, height: 80)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Fox")
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)

                    Text("Fox tale")
                        .font(.caption2)
                        .foregroundStyle(.white.secondary)
                }


                Spacer(minLength: 0)

                HStack {
                    Button("", systemImage: "star.circle.fill") {

                    }

                    Button("", systemImage: "ellipsis.circle.fill") {

                    }
                }
                .foregroundStyle(.white, .white.tertiary)
                .font(.title2)
            }

        }
        .padding(15)
        .padding(.top, safeArea.top)
    }

    func resizeWindow(_ progress: CGFloat) {
        /// first subview of keyWindow is swift app content
        /// then sheets/full screen covers, inspectors etc
        /// [min, max] of progress value is [0.1, 0.9]
        if let mainWindow = mainWindow?.subviews.first {
            let offsetY = (mainWindow.frame.height * progress) / 2

            /// personal preference (not work in preview)
            mainWindow.layer.cornerRadius = (progress / 0.1) * 30
            mainWindow.layer.masksToBounds = true

            mainWindow.subviews.first?.transform = .identity
                .scaledBy(x: 1 - progress, y: 1 - progress)
                .translatedBy(x: 0, y: offsetY)
        }
    }

    func resetResizeWindow() {
        if let mainWindow = mainWindow?.subviews.first {
            UIView.animate(withDuration: 0.3) {
                mainWindow.layer.cornerRadius = 0
                mainWindow.transform = .identity
            }
        }
    }
}

#Preview {
    RootView {
        UniversalOverlayAppleMiniPlayerDemoView()
    }
}
