//
//  ContentView.swift
//  MyMint
//
//  Created by IFang Lee on 5/14/24.
//

import SwiftUI

struct ContentView: View {
    /// Visibility Status
    @AppStorage("isFirstTime") private var isFirstTime: Bool = true
    /// Active  Tab
    @State private var activeTab: MintTab = .recents
    var body: some View {
        TabView(selection: $activeTab) {
            Recents()
                .tag(MintTab.recents)
                .tabItem { MintTab.recents.tabContent }
            
            Search()
                .tag(MintTab.search)
                .tabItem { MintTab.search.tabContent }
            
            Graphs()
                .tag(MintTab.charts)
                .tabItem { MintTab.charts.tabContent }
            
            Settings()
                .tag(MintTab.settings)
                .tabItem { MintTab.settings.tabContent }
        }
        .tint(appTint)
        .sheet(isPresented: $isFirstTime, content: {
            IntroScreen()
                .interactiveDismissDisabled()
        })
    }
}

#Preview {
    ContentView()
}
