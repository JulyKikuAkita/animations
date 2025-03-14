//
//  ProfileCardView.swift
//  Profiles

import SwiftUI

struct ProfileCardView: View {
    var profile: Profile
    @Binding var config: HeroConfiguration

    var onClick: (CGRect) -> Void

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
                    .opacity(config.activeId == profile.id.uuidString ? 0 : 1)
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
