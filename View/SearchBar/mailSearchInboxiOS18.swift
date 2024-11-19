//
//  mailSearchInboxiOS18.swift
//  animation

import SwiftUI

struct mailSearchInboxiOS18DemoView: View {
    @State private var searchText: String = ""
    @State private var isSearchActive: Bool = false
    @State private var activeTab: InboxTabModel = .primary
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                VStack(spacing: 0) {
                    InboxTabBar(activeTab: $activeTab)
                }
            }
            .navigationTitle("All Inboxes")
            .searchable(
                text: $searchText,
                isPresented: $isSearchActive,
                placement: .navigationBarDrawer(displayMode: .automatic)
            )
            .background(.gray.opacity(0.18))
        }
    }
}

struct InboxTabBar: View {
    @Binding var activeTab: InboxTabModel
    var body: some View {
        GeometryReader {  _  in
            HStack(spacing: 8) {
                HStack(spacing: 8) {
                    ForEach(
                        InboxTabModel.allCases.filter({ $0 != .allMails }),
                        id: \.rawValue
                    ) { tab in
                        ResizableTabButton(tab)
                    }
                }
            }
        }
        .frame(height: 50)
    }
    
    @ViewBuilder
    func ResizableTabButton(_ tab: InboxTabModel) -> some View {
        HStack(spacing: 8) {
            Image(systemName: tab.symbolImage)
                .font(.title3)
                .symbolVariant(activeTab == tab ? .fill : .none)
            
            if activeTab == tab {
                Text(tab.rawValue)
                    .font(.callout)
                    .fontWeight(.semibold)
            }
        }
        .frame(maxHeight: .infinity)
        .padding(.horizontal, 20)
        .background {
            Rectangle()
                .fill(activeTab == tab ? tab.color : .gray)
        }
        .clipShape(.rect(cornerRadius: 20, style: .continuous))
    }
}

#Preview {
    mailSearchInboxiOS18DemoView()
}
