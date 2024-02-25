//
//  BasicProfileAnimationView.swift
//  animation
//
//  how to build the custom matched geometry effect is with the help of the anchor preference API in SwiftUI.
// 1. know the source view anchor frame
// 2. when the detail view is pushed, add an overlay to the navigaton stack that will start from the source view and move to the destination view with the destination view anchor frame.
//
// source: https://www.youtube.com/watch?v=cyVQJ31AYKs&list=PLimqJDzPI-H97JcePxWNwBXJoGS-Ro3a-&index=22

import SwiftUI
//4:32
struct BasicProfileAnimationView: View {
    @State private var allProfiles: [Profile] = profiles

    var body: some View {
        List(profiles) { profile in
            HStack {
                Color.clear
                    .frame(width: 60, height: 60)
                    ///Source view anchor
                    .anchorPreference(key: MAnchorKey.self, value: .bounds, transform: { anchor in
                        return [profile.id.uuidString: anchor]
                    })
                
                VStack(alignment: .leading, spacing: 6, content: {
                    Text(profile.username)
                        .fontWeight(.semibold)
                    
                    Text(profile.lastMsg)
                        .font(.callout)
                        .textScale(.secondary)
                        .foregroundStyle(.gray)
                })
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(profile.lastActive)
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
        }
        /// Fetching source view anchor frame and added all the views as an overlay to the list view.
        .overlayPreferenceValue(MAnchorKey.self, { value in
            GeometryReader(content: { geometry in
                ForEach(profiles) { profile in
                    /// Fetching each profile image view using the profile id
                    if let anchor = value[profile.id.uuidString] {
                        let rect = geometry[anchor]
                        ImageView(profile: profile, size: rect.size)
                            .offset(x: rect.minX, y: rect.minY)
                    }
                }
            })
        })
    }
}

struct BasicProfileAnimationDetailedView: View {
    var body: some View {
        Text("")
    }
}
struct ImageView: View {
    var profile: Profile
    var size: CGSize
    var body: some View {
        Image(profile.profilePicture)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: size.width, height: size.height)
            .clipShape(.circle)
    }
}
#Preview {
    ContentView()
}
