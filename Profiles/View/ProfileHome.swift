//
//  ProfileHome.swift
//  Profiles
//  SwiftUI Navigation Stack Hero Animation - iOS 17 & 18
//  https://www.youtube.com/watch?v=vuMm9r5H8d0 2:04
import SwiftUI

struct ProfileHome: View {
    var body: some View {
        NavigationStack {
            List {
                ForEach(profiles) { profile in
                    ProfileCardView(profile: profile) { rect in
                        
                    }
                }
            }
            .navigationTitle("Messages")
        }
    }
}

struct ProfileCardView: View {
    var profile: Profile
    var onClick: (CGRect) -> ()
    
    /// View properties
    @State private var viewRect: CGRect = .zero
    var body: some View {
        Button {
            onClick(viewRect)
        } label: {
            HStack(spacing: 12) {
                Image(profile.profilePicture)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 45, height: 45)
                    .clipShape(.circle)
                    .onGeometryChange(for: CGRect.self) { /// new api of Xcode 16 to simplified create hero animation
                        $0.frame(in: .global)
                    } action: { newValue in
                        viewRect = newValue
                    }
                    
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(profile.username)
                        .font(.callout)
                        .foregroundStyle(Color.primary)
                    
                    Text(profile.lastMsg)
                        .font(.caption2)
                        .foregroundStyle(.gray)
                }
                
                Spacer(minLength: 0)
                
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.gray)
            }
            .contentShape(.rect)
        }
    }
}

#Preview {
    ProfileHome()
}
