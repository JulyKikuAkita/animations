//
//  PSHeaderView.swift
//  PlayStationApp

import SwiftUI

struct PSHeaderView: View {
    var size: CGSize
    /// View Properties
    @State private var activeTab: PSHeaderTab = .chat
    var body: some View {
        if #available(iOS 18, *) {
//            TabView(selection: $activeTab) {
//                SwiftUI.Tab.init(value: .chat) {
//                    Text("Chat")
//                }
//                
//                SwiftUI.Tab.init(value: .friends) {
//                    Text("Friends")
//                }
//            }
        } else {
            
        }
    }
}

#Preview {
    ContentView()
}
