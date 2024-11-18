//
//  ProfileDetailView.swift
//  Profiles

import SwiftUI

struct ProfileDetailView: View {
    var profile: Profile
    @Binding var config: HeroConfiguration
    public var body: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 15) {
                ForEach(messages) { message in
                    MessageCardView(message: message)
                }
            }
            .padding(15)
        }
        .safeAreaInset(edge: .top) {
            CustomHeaderView()
        }
        .hideNavBarBackground()
    }
    
    @ViewBuilder
    func CustomHeaderView() -> some View {
        VStack(spacing: 6) {
            Image(profile.profilePicture)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 50, height: 50)
                .clipShape(.circle)
            
            Button {
                
            } label: {
                HStack(spacing: 2) {
                    Text(profile.username)
                    
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                }
                .font(.caption)
                .foregroundStyle(Color.primary)
                .contentShape(.rect)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, -25) /// adjust padding but keep navigation bar for interaction
        .padding(.bottom, 15)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
        }
    }
}

extension View {
    @ViewBuilder
    func hideNavBarBackground() -> some View {
        if #available(iOS 18, *) {
            self
                .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
        } else {
            self
                .toolbarBackground(.hidden, for: .navigationBar)
        }
       
    }
}

#Preview {
    ProfileHome()
}
