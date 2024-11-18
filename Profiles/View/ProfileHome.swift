//
//  ProfileHome.swift
//  Profiles
//  SwiftUI Navigation Stack Hero Animation - iOS 17 & 18
import SwiftUI

struct ProfileHome: View {
    /// Hero configuration
    @State private var config: HeroConfiguration = .init()
    @State private var selectedProfile: Profile?
    var body: some View {
        NavigationStack {
            List {
                ForEach(profiles) { profile in
                    ProfileCardView(profile: profile, config: $config) { rect in
                        config.coordinates.0 = rect
                        config.coordinates.1 = rect
                        config.layer = profile.profilePicture
                        config.activeId = profile.id.uuidString
                        /// setup for navigation destination
                        selectedProfile = profile
                    }
                }
            }
            .navigationTitle("Messages")
            .navigationDestination(item: $selectedProfile) { profile in
                ProfileDetailView(profile: profile, config: $config)
            }
        }
        .overlay(alignment: .topLeading) { /// overlay should be above navigation stack so won't be push away
            /// hero animation on the location of source and destination coordinates
            /// when view is detail view is pushed, animate transition from source to dest location for 0.35s then hide the overlay view
            /// when view is view is dismissed, reset the overlay position back to source location to finish animation. Then reset all config to 0
            ZStack {
                if let image = config.layer {
                    let destination = config.coordinates.1
                    
                    Image(image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: destination.width, height: destination.height)
                        .clipShape(.circle)
                        .offset(x: destination.minX, y: destination.minY)
                }
            }
            .ignoresSafeArea()
        }
    }
}

#Preview {
    ProfileHome()
}
