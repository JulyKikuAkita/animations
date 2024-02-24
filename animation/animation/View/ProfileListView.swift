//
//  ProfileListView.swift
//  animation
//
//  Created by IFang Lee on 2/23/24.
//

import SwiftUI

struct ProfileListView: View {
    @State private var allProfiles: [Profile] = profiles
    @State private var selectedProfile: Profile?
    @State private var showDetail: Bool = false
    
    var body: some View {
        NavigationStack {
            List(allProfiles) { profile in
                HStack {
                    Image(profile.profilePicture)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .clipShape(.circle)
                    
                    VStack(alignment: .leading, spacing: 6, content: {
                        Text(profile.username)
                            .fontWeight(.semibold)
                        
                        Text(profile.lastMsg)
                            .font(.caption2)
                            .foregroundStyle(.gray)
                    })
                }
                .contentShape(.rect)
                .onTapGesture {
                    selectedProfile = profile
                    showDetail = true
                }
            }
            .navigationTitle("Progress Effect")
        }
        .overlay {
            DetailedView(
                selectedProfile: $selectedProfile,
                showDetail: $showDetail
            )
        }
    }
}

struct DetailedView: View {
    @Binding var selectedProfile: Profile?
    @Binding var showDetail: Bool
    
    var body: some View {
        if let selectedProfile, showDetail {
            GeometryReader {
                let size = $0.size
                ScrollView(.vertical) {
                    /// Detailed image view
                    Image(selectedProfile.profilePicture)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size.width, height: 400)
                        .clipped()
                }
                .scrollIndicators(.hidden)
                .ignoresSafeArea()
                .frame(width: size.width, height: size.height)
            }
        }
    }
}

#Preview {
    ContentView()
}
