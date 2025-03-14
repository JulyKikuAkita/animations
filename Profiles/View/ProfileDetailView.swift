//
//  ProfileDetailView.swift
//  Profiles

import SwiftUI

struct ProfileDetailView: View {
    @Binding var selectedProfile: Profile?
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
            if #unavailable(iOS 18) {
                CustomHeaderView()
                    .padding(.vertical, 15)
                    .background {
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .ignoresSafeArea()
                    }
            } else {
                CustomHeaderView()
                    .padding(.top, -25) /// adjust padding but keep navigation bar for interaction
                    .padding(.bottom, 15)
                    .background {
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .ignoresSafeArea()
                    }
            }
        }
        .hideNavBarBackground()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                config.isExpandedCompletely = true
            }
        }
    }

    @ViewBuilder
    func CustomHeaderView() -> some View {
        VStack(spacing: 6) {
            ZStack {
                if selectedProfile != nil {
                    Image(profile.profilePicture)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipShape(.circle)
                        .opacity(config.isExpandedCompletely ? 1 : 0)
                        .onGeometryChange(for: CGRect.self) {
                            $0.frame(in: .global)
                        } action: { newValue in
                            config.coordinates.1 = newValue
                        }
                        .transition(.identity)
                }
            }
            .frame(width: 50, height: 50)

            Button {} label: {
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
        .overlay(alignment: .topLeading) {
            if #unavailable(iOS 18) {
                Button {
                    selectedProfile = nil
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding(.trailing, 20)
                        .contentShape(.rect)
                }
                .padding(.leading, 15)
            }
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
            toolbar(.hidden, for: .navigationBar)
                .navigationBarBackButtonHidden()
        }
    }

    @ViewBuilder
    func hideNavBarBackgroundProfileHome() -> some View {
        if #available(iOS 18, *) {
            self
        } else {
            toolbar(.hidden, for: .navigationBar)
        }
    }
}

#Preview {
    ProfileHome()
}
