//
//  PSHeaderView.swift
//  PlayStationApp

import SwiftUI

struct PSHeaderView: View {
    var size: CGSize
    /// View Properties
    @State private var activeTab: PSHeaderTab = .chat
    var body: some View {
        let height: CGFloat = size.height + safeArea.top

        VStack(spacing: 0) {
            Group {
                if #available(iOS 18, *) {
                    TabView(selection: $activeTab) {
                        SwiftUI.Tab.init(value: .chat) {
                            Text("Chat")
                        }

                        SwiftUI.Tab.init(value: .friends) {
                            Text("Friends")
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                } else {
                    TabView(selection: $activeTab) {
                        Text("Chat")
                            .tag(PSHeaderTab.chat)

                        Text("Friends")
                            .tag(PSHeaderTab.friends)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }

            /// minimized header view
            Rectangle()
                .fill(.pink)
                .frame(height: 50)
        }
        .frame(height: height)
        .offset(y: -(height - 50))
    }
}

#Preview {
    ContentView()
}
