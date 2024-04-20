//
//  AppleMusicHomeView.swift
//  animation

import SwiftUI

struct AppleMusicConstant {
    /// View constants
    static let defaultTabBarHeight: CGFloat = 49
    static let miniPlayerHeight: CGFloat = 70
}

struct AppleMusicHomeView: View {
    /// Animation properties
    @State private var expandSheet: Bool = false
    @Namespace private var animation
    
    var body: some View {
        TabView {
            SampleTab(AppleMusicTab.listenNow.title, AppleMusicTab.listenNow.rawValue)
            SampleTab(AppleMusicTab.browse.title, AppleMusicTab.browse.rawValue)
            SampleTab(AppleMusicTab.radis.title, AppleMusicTab.radis.rawValue)
            SampleTab(AppleMusicTab.music.title, AppleMusicTab.music.rawValue)
            SampleTab(AppleMusicTab.search.title, AppleMusicTab.search.rawValue)
        }
        /// Changing tab indicator color
        .tint(.red)
        .safeAreaInset(edge: .bottom) {
            CustomBottomSheet()
        }
        .overlay {
            if expandSheet {
                ExpandedBottomSheet(expandSheet: $expandSheet, animation: animation)
                /// Transition for more fluent animation // check https://www.youtube.com/watch?v=fOaARtT3_a4&t=0s for why to use y: -5
                    .transition(.asymmetric(insertion: .identity, removal: .offset(y: -5)))
            }
        }
    }
    
    @ViewBuilder
    func CustomBottomSheet() -> some View {
        ZStack {
            Rectangle()
                .fill(.ultraThickMaterial)
                .overlay {
                    MusicInfoView(expandSheet: $expandSheet, animation: animation)
                }
        }
        .frame(height: AppleMusicConstant.miniPlayerHeight)
        /// Separator line
        .overlay(alignment: .bottom, content: {
            Rectangle()
                .fill(.gray.opacity(0.1))
                .frame(height: 1)
//                .offset(y: -10)
        })
        .offset(y: -AppleMusicConstant.defaultTabBarHeight)
    }
    
    
    @ViewBuilder
    func SampleTab(_ title: String, _ icon: String) -> some View {
        Text(title)
            .tabItem {
                Image(systemName: icon)
                Text(title)
            }
        /// changing tab background color
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(.ultraThickMaterial, for: .tabBar)
    }
}

#Preview {
    AppleMusicHomeView()
        .preferredColorScheme(.dark)
}
