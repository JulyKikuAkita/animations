//
//  ProfileList+SheetView.swift
//  animation
//
//  source: https://www.youtube.com/watch?v=zHtB8mHPLDU&list=PLimqJDzPI-H97JcePxWNwBXJoGS-Ro3a-&index=32
//

import SwiftUI
10:51
struct ProfileList_SheetView: View {
    var body: some View {
        NavigationStack {
            ProfileSheetAnimationView()
                .navigationTitle("Sheet Style")
        }
    }
}

struct ProfileSheetAnimationView: View {
    @State var selectedProfile: Profile?
    @State var showProfileView: Bool = false
    /// this will crash preview but works at simulator
    @Environment(SceneDelegate.self) private var sceneDelegate
    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 15) {
                ForEach(profiles) { profile in
                    HStack(spacing: 12) {
                        Image(profile.profilePicture)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 50)
                            .clipShape(.circle)
                            .contentShape(.circle)
                            .onTapGesture {
                                /// Opening profile
                                selectedProfile = profile
                                showProfileView.toggle()
                            }
                        
                        VStack(alignment: .leading, spacing: 4, content: {
                            Text(profile.username)
                                .fontWeight(.bold)
                            
                            Text(profile.lastMsg)
                                .font(.caption)
                                .foregroundStyle(.gray)
                        })
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text(profile.lastActive)
                            .font(.caption2)
                            .foregroundStyle(.gray)
                    }
                }
            }
            .padding(15)
            .padding(.horizontal, 5)
        }
        .scrollIndicators(.hidden)
        .sheet(isPresented: $showProfileView, content: {
            DetailedSheetProfileView(
                selectedProfile: $selectedProfile,
                showProfileView: $showProfileView
            )
            .presentationDetents([.medium, .large])
            .presentationCornerRadius(25)
            .interactiveDismissDisabled() // in order to present animation
            
        })
    }
}

/// Detail profile view
struct DetailedSheetProfileView: View {
    @Binding var selectedProfile: Profile?
    @Binding var showProfileView: Bool
    /// Color Scheme
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        VStack {
            GeometryReader(content: { geometry in
                let size = geometry.size
                
                if let selectedProfile {
                    Image(selectedProfile.profilePicture)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size.width, height: size.height)
                        .overlay {
                            let color = scheme == .dark ? Color.black : Color.white
                            LinearGradient(colors: [
                                .clear,
                                .clear,
                                .clear,
                                color.opacity(0.1),
                                color.opacity(0.5),
                                color.opacity(0.9),
                                color
                            ], startPoint: .top, endPoint: .bottom)
                        }
                        .clipped()

                }
            })
            .frame(maxHeight: 330)
            .overlay(alignment: .topLeading) {
                Button(action: {
                    /// Closing Profile
                    showProfileView = false
                }, label: {
                    Image(systemName: "xmark")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .contentShape(.rect)
                        .padding(10)
                        .background(.black, in: .circle)
                })
                .padding([.leading, .top], 20)
            }
            
            Spacer()
        }
    }
}
#Preview {
    ContentView()
}
