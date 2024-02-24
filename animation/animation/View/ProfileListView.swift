//
//  ProfileListView.swift
//  animation
//
//  Created by IFang Lee on 2/23/24.
//

import SwiftUI
// 13:16
struct ProfileListView: View {
    @State private var allProfiles: [Profile] = profiles
    @State private var selectedProfile: Profile?
    @State private var showDetail: Bool = false
    @State private var heroProgress: CGFloat = 0
    @State private var showHeroView: Bool = true

    var body: some View {
        NavigationStack {
            List(allProfiles) { profile in
                HStack {
                    Image(profile.profilePicture)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .clipShape(.circle)
                        .anchorPreference(key: AnchorKey.self, value: .bounds, transform: { anchor in
                            return [profile.id.uuidString: anchor]
                        })
                    
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
                    
                    withAnimation(.snappy(duration: 0.35, extraBounce: 0), completionCriteria: .logicallyComplete) {
                        heroProgress = 1.0
                    } completion: {
                        Task {
                            /// adding delay for the heroview overlay
                            try? await Task.sleep(for: .seconds(0.1))
                            showHeroView = false
                        }
                    }
                }
            }
            .navigationTitle("Progress Effect")
        }
        .overlay {
            DetailedView(
                selectedProfile: $selectedProfile,
                showDetail: $showDetail, 
                heroProgress: $heroProgress, 
                showHeroView: $showHeroView
            )
        }
        // Hero Animation Layer
        .overlayPreferenceValue(AnchorKey.self, { value in
            GeometryReader { geometry in
                if let selectedProfile,
                    let source = value[selectedProfile.id.uuidString],
                   let destination = value["DESTINATION"] {
                    let sourceRect = geometry[source]
                    let radius = sourceRect.height / 2
                    let destinationRect = geometry[destination]
                    
                    let diffSize = CGSize(
                        width: destinationRect.width - sourceRect.width,
                        height: destinationRect.height - sourceRect.height
                    )
                    
                    let diffOrigin = CGPoint(
                        x: destinationRect.minX - sourceRect.minX,
                        y: destinationRect.minY - sourceRect.minY
                    )
                    
                    // TODO: put hero view here
                    Image(selectedProfile.profilePicture)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(
                            width: sourceRect.width + (diffSize.width * heroProgress),
                            height: sourceRect.height + (diffSize.height * heroProgress)
                        )
                        .clipShape(.rect(cornerRadius: radius - (radius * heroProgress)))
                        .offset(
                            x: sourceRect.minX + (diffOrigin.x * heroProgress),
                            y: sourceRect.minY + (diffOrigin.y * heroProgress)
                        )
                        .opacity(showHeroView ? 1 : 0)
                }
            }
        })
        /// some visual help
        .overlay(alignment: .bottom) {
            Slider(value: $heroProgress)
                .padding(/*@START_MENU_TOKEN@*/EdgeInsets()/*@END_MENU_TOKEN@*/)
        }
    }
}

struct DetailedView: View {
    @Binding var selectedProfile: Profile?
    @Binding var showDetail: Bool
    @Binding var heroProgress: CGFloat
    @Binding var showHeroView: Bool

    /// Color scheme based background color
    @Environment(\.colorScheme) private var scheme
    
    /// Gesture properties
    @GestureState private var isDragging: Bool = false
    var body: some View {
        if let selectedProfile, showDetail {
            GeometryReader {
                let size = $0.size
                ScrollView(.vertical) {
                    /// Detailed profile image view
                    Rectangle()
                        .fill(.clear)
                        .overlay {
                            if !showHeroView {
                                Image(selectedProfile.profilePicture)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: size.width, height: 400)
                                    .clipShape(.rect(cornerRadius: 25))
                                    .transition(.identity)
                            }
                        }
                        .frame(height: 400)
                    /// Destination Anchor Frame
                        .anchorPreference(key: AnchorKey.self, value: .bounds, transform: { 
                            anchor in
                            return ["DESTINATION": anchor]
                        })
                        .visualEffect { content, geometryProxy in
                            content // add drag down offset
                                .offset(y: geometryProxy.frame(in: .scrollView).minY > 0 ? -geometryProxy.frame(in: .scrollView).minY : 0)
                        }
                }
                .scrollIndicators(.hidden)
                .ignoresSafeArea()
                .frame(width: size.width, height: size.height)
                .background {
                    Rectangle()
                        .fill(scheme == .dark ? .black : .white)
                        .ignoresSafeArea()
                }
                /// Close button
                .overlay(alignment: .topLeading) {
                    Button(action: { 
                        showHeroView = true
                        withAnimation(.snappy(duration: 0.35, extraBounce: 0), 
                                      completionCriteria: .logicallyComplete) {
                            heroProgress = 0.0
                        } completion: {
                            showDetail = false
                            self.selectedProfile = nil
                        }
                        
                    }, label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.largeTitle)
                            .imageScale(.medium)
                            .contentShape(.rect)
                            .foregroundStyle(.white, .black)
                    })
                    .buttonStyle(.plain)
                    .padding()
                    .opacity(showHeroView ? 0 : 1)
                    .animation(.snappy(duration: 0.2, extraBounce: 0), value: showHeroView)
                }
                .offset(x: size.width - (size.width * heroProgress))
            }
        }
    }
}

#Preview {
    ContentView()
}
