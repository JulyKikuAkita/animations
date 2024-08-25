//
//  PSHome.swift
//  PlayStationApp

import SwiftUI

struct PSHome: View {
    /// Tab bar properties
    @State private var activeTab: PS_Tab = .play
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            /// Custom tab bar
            PSTabbarView(activeTab: $activeTab)
        }
        .ignoresSafeArea(.all, edges: .bottom)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            Rectangle()
                .fill(.background)
                .ignoresSafeArea()
        }
        /// Hiding the home view indicator at the bottom
        .persistentSystemOverlays(.hidden)
        .overlay {
            GeometryReader {
                let size = $0.size
                PSHeaderView(size: size)
            }
        }
    }
}

#Preview {
    PSHome()
}
