//
//  LocationPermissionFullSheetView.swift
//  animation
//
//  Created on 11/14/25.

import CoreLocation
import SwiftUI

struct LocationPermissionAnimationDemoView: View {
    let config = LocationPermissionViewConfig(appName: "Nanachi App")
    var body: some View {
        Text("Hello, World!")
            .locationPermissionFullScreenCover(
                isPresented: .constant(true),
                config: config
            ) {
                Text("Hello, World!")
            } authorizationDidChange: { _ in

            } askLater: {}
    }
}

struct LocationPermissionViewConfig {
    var appName: String
    var tint: Color = .pink
    var mapPinTint: Color = .white
    var mapPulseTint: Color = .white
    var showsMapPinANDPulse: Bool = true
    var dimsScreenContent: Bool = true
    var showsDynamicIsland: Bool = false
    var initialDDelay: Double = 0.35
    var pinAndPulseOffset: CGSize = .zero
}

extension View {
    @ViewBuilder
    func locationPermissionFullScreenCover(
        isPresented: Binding<Bool>,
        config: LocationPermissionViewConfig,
        @ViewBuilder screenContent: @escaping () -> some View,
        authorizationDidChange: @escaping (CLAuthorizationStatus) -> Void,
        askLater: @escaping () -> Void

    ) -> some View {
        fullScreenCover(isPresented: isPresented) {
            LocationPermissionFullSheetView(
                isPresented: isPresented,
                config: config,
                screenContent: screenContent,
                authorizationDidChange: authorizationDidChange,
                askLater: askLater
            )
            .presentationBackground(.background)
        }
    }
}

private struct LocationPermissionFullSheetView<ScreenContent: View>: View {
    @Binding var isPresented: Bool
    var config: LocationPermissionViewConfig
    @ViewBuilder var screenContent: ScreenContent
    var authorizationDidChange: (CLAuthorizationStatus) -> Void
    var askLater: () -> Void
    var body: some View {
        GeometryReader {
            let size = $0.size
            let safeArea = $0.safeAreaInsets
            /// effective screen size after animation
            let resizeHeight = size.height - (280 + safeArea.bottom)
            let scale = resizeHeight / size.height
            let cornerRadius = min(size.height * 0.07, 60)

            ZStack {
                /// Background Action Content
                VStack(spacing: 15) {
                    Text(config.appName)
                        .font(.title2)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    Text("Allow **\(config.appName)** to access your \nlocation while **you're using the app**.")
                        .font(.callout)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)

                    Button {} label: {
                        Text("Allow Access")
                            .fontWeight(.medium)
                            .frame(maxWidth: 300)
                            .padding(.vertical, 5)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(config.tint)
                    .padding(.top, 10)

                    Button("Ask Me Later") {}
                        .fontWeight(.semibold)
                        .foregroundStyle(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 15)
                .padding(.bottom, 10)
                .padding(.top, resizeHeight + safeArea.top + 25)
                /// Taking all available space
                .frame(maxHeight: .infinity, alignment: .center)
                .fontDesign(.rounded)
                .ignoresSafeArea(.all, edges: .bottom)

                /// Resizing window
                Rectangle()
                    .foregroundStyle(.clear)
                    /// prevent current view size change
                    .overlay {
                        screenContent
                    }
                    .clipShape(.rect(cornerRadius: cornerRadius))
                    .overlay {
                        /// phone like  border
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.primary, lineWidth: 15)
                    }
                    .scaleEffect(scale, anchor: .top)
                    .offset(y: safeArea.top + 25)
                    .ignoresSafeArea()
            }
        }
    }
}

#Preview {
    LocationPermissionAnimationDemoView()
}
