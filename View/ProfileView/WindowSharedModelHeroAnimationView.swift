//
//  WindowSharedModelHeroAnimationView.swift
//  animation
//
//

import SwiftUI
struct CustomHeroAnimationView: View {
    /// Color Scheme
    @Environment(\.colorScheme) private var scheme
    @Environment(WindowSharedModel.self) private var windowShareModel
    var body: some View {
        GeometryReader(content: { geometry in
            VStack {
                let sourceRect = windowShareModel.sourceRect
                if let selectedProfile = windowShareModel.selectedProfile, windowShareModel.hideNativeView {
                    Image(selectedProfile.profilePicture)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: sourceRect.width, height: sourceRect.height)
                        .overlay {
                            let color = scheme == .dark ? Color.black : Color.white
                            LinearGradient(colors: [
                                .clear,
                                .clear,
                                .clear,
                                color.opacity(0.1),
                                color.opacity(0.5),
                                color.opacity(0.9),
                                color
                            ], startPoint: .top, endPoint: .bottom)
                            .opacity(windowShareModel.showGradient ? 1 : 0)
                        }
                        .clipShape(.rect(cornerRadius: windowShareModel.cornerRadius))
                        .offset(x: sourceRect.minX, y: sourceRect.minY)
                        .animation(.snappy(duration: 0.3, extraBounce: 0), value: windowShareModel.showGradient)

                }
            }
            /// animating frame changes
            .animation(.snappy(duration: 0.3, extraBounce: 0), value: windowShareModel.sourceRect)
            .ignoresSafeArea()
        })
    }
}
