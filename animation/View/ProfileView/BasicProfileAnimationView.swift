//
//  BasicProfileAnimationView.swift
//  animation
//
//  how to build the custom matched geometry effect is with the help of the anchor preference API in SwiftUI.
// 1. know the source view anchor frame
// 2. when the detail view is pushed, add an overlay to the navigaton stack that will start from the source view and move to the destination view with the destination view anchor frame.
// 3. by animating the size and destination anchor, we can achieve a custom geomtry animation effect
// source: https://www.youtube.com/watch?v=cyVQJ31AYKs&list=PLimqJDzPI-H97JcePxWNwBXJoGS-Ro3a-&index=22

import SwiftUI
struct BasicProfileAnimationListView: View {
    /// View properties
    @State private var selectedProfile: Profile?
    @State private var pushView: Bool = false
    /// first bool indicates if animation is finised, and when finished, remove the overlay view
    ///  sec bool to animate contents like buttons and header views in the detailed view
    @State private var hideView: (Bool, Bool) = (false, false)
    
    /// Drop down View properties
    @State private var selection: String?
    @State private var selection2: String?
    @State private var selection3: String?

    var body: some View {
        NavigationStack {
            VStack {
                BasicProfileAnimationView(selectedProfile: $selectedProfile, pushView: $pushView)
                    .navigationTitle("Profile")
                    .navigationDestination(isPresented: $pushView) {
                        BasicProfileAnimationDetailedView(
                            selectedProfile: $selectedProfile,
                            pushView: $pushView,
                            hideView: $hideView
                        )
                    }
                
                DropDownView(
                    hint: "Select",
                    options: ["Shiba", "Akita", "Bernes", "Doodle", "Malamute"],
                    anchor: .top,
                    selection: $selection
                )
                
                DropDownView(
                    hint: "Select",
                    options: ["list", "grid", "stack"],
                    anchor: .bottom,
                    selection: $selection2
                )
                
                DropDownView(
                    hint: "Select",
                    options: ["1", "2", "3"],
                    anchor: .top,
                    selection: $selection3
                )

            }
        }
        .overlayPreferenceValue(AnchorKey.self, { value in
            GeometryReader(content: { geometry in
                if let selectedProfile, 
                    let anchor = value[selectedProfile.id.uuidString],
                   !hideView.0 {
                    let rect = geometry[anchor]
                    ImageView(profile: selectedProfile, size: rect.size)
                        .offset(x: rect.minX, y: rect.minY)
                    /// Simply animating the rect will add the geometry effect we needed
                        .animation(.snappy(duration: 0.35, extraBounce: 0), value: rect)
                }
            })

        })
    }
}

struct BasicProfileAnimationView: View {
    @Binding var selectedProfile: Profile?
    @Binding var pushView: Bool
    var body: some View {
        List(profiles) { profile in
            Button(action: {
                selectedProfile = profile
                pushView.toggle()
            }, label: {
                HStack {
                    Color.clear
                        .frame(width: 60, height: 60)
                        ///Source view anchor
                        .anchorPreference(key: AnchorKey.self, value: .bounds,
                                          transform: { anchor in
                            return [profile.id.uuidString: anchor]
                        })
                    
                    VStack(alignment: .leading, spacing: 6, content: {
                        Text(profile.username)
                            .fontWeight(.semibold)
                            .foregroundStyle(.black)
                        
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
            })
        }
        /// Fetching source view anchor frame and added all the views as an overlay to the list view.
        /// Need to disable the default list back action to achieve custom geometry effect
        /// Since it's an overlay, we cannot tap on image
        /// Enable tap on image by disable allowsHitTesting
        .overlayPreferenceValue(AnchorKey.self, { value in
            GeometryReader(content: { geometry in
                ForEach(profiles) { profile in
                    /// Fetching each profile image view using the profile id
                    /// Hiding the current tapped view
                    if let anchor = value[profile.id.uuidString], selectedProfile?.id != profile.id {
                        let rect = geometry[anchor]
                        ImageView(profile: profile, size: rect.size)
                            .offset(x: rect.minX, y: rect.minY)
                            .allowsHitTesting(false)
                    }
                }
            })
        })
    }
}

struct BasicProfileAnimationDetailedView: View {
    @Binding var selectedProfile: Profile?
    @Binding var pushView: Bool
    @Binding var hideView: (Bool,Bool)
    var body: some View {
        if let selectedProfile {
            VStack {
                GeometryReader(content: { geometry in
                    let size = geometry.size
                    VStack {
                        if hideView.0 {
                            ImageView(profile: selectedProfile, size: size)
                            /// Custom close button
                                .overlay(alignment: .top) {
                                    ZStack {
                                        Button(action: {
                                            hideView.0 = false
                                            hideView.1 = false
                                            pushView = false
                                            /// sync animation duration with the navigation view pops up time: 0.35s
                                            ///  when view pop ups, set the selec profile to nil
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                                self.selectedProfile = nil
                                            }
                                        }, label: {
                                            Image(systemName: "xmark")
                                                .foregroundStyle(.white)
                                                .padding(10)
                                                .background(.black, in: .circle)
                                                .contentShape(.circle)
                                        })
                                        .padding(15)
                                        .padding(.top, 40)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)

                                        Text(selectedProfile.username)
                                            .font(.title.bold())
                                            .foregroundStyle(.black)
                                            .padding(15)
                                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                                    }
                                    .opacity(hideView.1 ? 1 : 0)
                                    .animation(.snappy, value: hideView.1)
                                }
                                .onAppear(perform: {
                                    /// Remove the animation view once the animation is finished
                                    /// Best to sync with the time that the navigation view pops up, 0.35s
                                    DispatchQueue.main.asyncAfter(deadline: .now()) {
                                        hideView.1 = true
                                    }
                                })
                        } else {
                            Color.clear
                        }
                    }
                    /// Destination view anchor
                    .anchorPreference(key: AnchorKey.self, value: .bounds,
                                      transform: { anchor in
                        return [selectedProfile.id.uuidString: anchor]
                    })
                })
                .frame(height: 400)
                .ignoresSafeArea()
                
                Spacer(minLength: 0)
            }
            .toolbar(hideView.0 ? .hidden : .visible, for: .navigationBar)
            .onAppear(perform: {
                /// Remove the animation view once the animation is finished
                /// Best to sync with the time that the navigation view pops up:
                /// which is  0.35s + amount of snappy animation duration
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    hideView.0 = true
                }
            })
        }
       
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
        /// Linear GRadient at bottom
            .overlay(content: {
                LinearGradient(colors: [
                    .clear,
                    .clear,
                    .clear,
                    .white.opacity(0.1),
                    .white.opacity(0.5),
                    .white.opacity(0.9),
                    .white
                ], startPoint: .top, endPoint: .bottom)
                .opacity(size.width > 60 ? 1 : 0)
            })
            /// make sourcce circle shape and destination rect shape
            .clipShape(.rect(cornerRadius: size.width > 60 ? 0 : 30)) // source size is 60
    }
}
#Preview {
    ContentView()
}
