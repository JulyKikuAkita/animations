//
//  SideBarView.swift
//  animation

import SwiftUI

struct SideBarView: View {
    @Binding var path: NavigationPath
    var toggleSideBar: () -> ()
    var body: some View {
        GeometryReader {
            let safeArea = $0.safeAreaInsets
            let isSidesHavingValues = safeArea.leading != 0 || safeArea.trailing != 0
            
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 6) {
                    Image(.fox)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                        .clipShape(.circle)
                    
                    Text("Mr. Fox")
                        .font(.callout)
                        .fontWeight(.semibold)
                    
                    Text("@FoxFarm")
                        .font(.caption2)
                        .foregroundStyle(.gray)
                    
                    HStack(spacing: 4) {
                        Text("3.1K")
                            .fontWeight(.semibold)
                        
                        Text("Following")
                            .font(.caption)
                            .foregroundStyle(.gray)
                        
                        Text("1.8M")
                            .fontWeight(.semibold)
                            .padding(.leading, 5)
                        
                        Text("Followers")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                    .font(.system(size: 14))
                    .lineLimit(1)
                    .padding(.top, 5)
                    
                    /// Side bar navigation items
                    VStack(alignment: .leading, spacing: 20) {
                        ForEach(SideBarActions.allCases, id: \.rawValue) { action in
                            SideBarActionButton(value: action) {
                                toggleSideBar()
                                path.append(action.rawValue) /// alt, pass the entire action (conforming to Hashable) and push view s based on it
                            }
                        }
                    }
                    .padding(25)
                }
                .padding(.vertical, 15)
                .padding(.horizontal, isSidesHavingValues ? 5 : 15)
            }
            .scrollClipDisabled()
            .scrollIndicators(.hidden)
            .background {
                Rectangle()
                    .fill(.background)
                    .overlay(alignment: .trailing) {
                        Rectangle()
                            .fill(.gray.opacity(0.35))
                            .frame(width: 1)
                    }
                    .ignoresSafeArea()
            }
            
        }
    }
    
    @ViewBuilder
    func SideBarActionButton(value: SideBarActions, action: @escaping () -> ()) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: value.symbolImage)
                    .font(.title3)
                    .frame(width: 30)
                
                Text(value.rawValue)
                    .fontWeight(.semibold)
                
                Spacer(minLength: 0)
            }
            .foregroundStyle(Color.primary)
            .padding(.vertical, 10)
            .contentShape(.rect)
        }
    }
}

/// Side Bar Actions
enum SideBarActions: String, CaseIterable {
    case communities = "Communities"
    case bookmarks = "Bookmarks"
    case lists = "Lists"
    case messages = "Messages"
    case monetization = "Monetization"
    case settings = "Settings"
    
    var symbolImage: String {
        switch self {
        case .communities: "person.2"
        case .bookmarks: "bookmark"
        case .lists: "list.bullet.clipboard"
        case .messages: "message.badge.waveform"
        case .monetization: "banknote"
        case .settings: "gearshape"
        }
    }
}

#Preview {
    @Previewable @State var navigationPath: NavigationPath = .init()
    SideBarView(path: $navigationPath, toggleSideBar: {})
}
