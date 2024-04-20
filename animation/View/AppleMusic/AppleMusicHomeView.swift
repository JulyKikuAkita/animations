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
            ListenView()
                .tabItem {
                    Image(systemName: AppleMusicTab.listenNow.rawValue)
                    Text("Listen Now")
                }
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
    
    /// Custom listen now  view
    @ViewBuilder
    func ListenView() -> some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    Image("IMG_0202")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    
                    Image("IMG_0206")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
                .padding()
                .padding(.bottom, 100)
            }
            .navigationTitle("Listen now")
        }
    }
    
    
    /// Custom bottom sheet
    @ViewBuilder
    func CustomBottomSheet() -> some View {
        /// Animating sheet background (to look like it's expanding from the bottom)
        ZStack {
            if expandSheet {
                Rectangle()
                    .fill(.clear)
            } else {
                Rectangle()
                    .fill(.ultraThickMaterial)
                    .overlay {
                        /// Music info
                        MusicInfoView(expandSheet: $expandSheet, animation: animation)
                    }
                    .matchedGeometryEffect(id: "BGVIEW", in: animation)
            }
        }
        .frame(height: AppleMusicConstant.miniPlayerHeight)
        /// Separator line
        .overlay(alignment: .bottom, content: {
            Rectangle()
                .fill(.gray.opacity(0.3))
                .frame(height: 1)
                .offset(y: -5)
        })
        .offset(y: -AppleMusicConstant.defaultTabBarHeight)
    }
    
    
    @ViewBuilder
    func SampleTab(_ title: String, _ icon: String) -> some View {
        /// iOS bug of tab bar animation, it can be avoided by wrapping the view inside scrollview
        ScrollView(.vertical, showsIndicators: false, content: {
            Text(title)
        })
        .tabItem {
            Image(systemName: icon)
            Text(title)
        }
        /// changing tab background color
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(.ultraThickMaterial, for: .tabBar)
        /// Hiding tab bar when sheet is expanded
        .toolbar(expandSheet ? .hidden : .visible, for: .tabBar)
    }
}

#Preview {
    AppleMusicHomeView()
        .preferredColorScheme(.dark)
}
