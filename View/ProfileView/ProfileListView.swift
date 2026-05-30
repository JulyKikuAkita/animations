//
//  ProfileListView.swift
//  animation
//
//  ⚠️  WIRED INTO THE APP: referenced from
//      `View/LandingPages/PlayerAnimationView.swift`. Don't rename or
//      delete without updating that demo browser.
//
//  Learning point
//  ──────────────
//  Three independent techniques layered into one demo screen:
//
//    1. Anchor-preference hero animation driven by an explicit
//       `heroProgress: CGFloat` (0...1). Unlike the other hero
//       demos, the morph is NOT just an implicit animation on a
//       rect — every dimension (width, height, x, y, corner radius)
//       is computed as `source + (destination - source) * progress`.
//       Exposing the slider at the bottom of the screen makes the
//       interpolation math visible and lets you scrub the morph.
//
//    2. Interactive SWIPE-TO-DISMISS on the detail view. A 10pt
//       leading edge "grab strip" hosts a `DragGesture` that maps
//       horizontal translation into the SAME `heroProgress` value,
//       so the hero layer literally tracks the finger backward
//       toward the source row.
//
//    3. App-Store / iOS-Settings style DARK MODE TOGGLE: snapshot
//       the screen before and after the toggle, stack both images,
//       and reveal the new one through a circular mask anchored to
//       the toggle button — using `.darkModeRect` (project helper)
//       to get the button's screen rect and `.createImages`
//       (project helper) to make the snapshot pair.
//
//  Key APIs
//  ────────
//  • `.anchorPreference(key: AnchorKey.self, value: .bounds)` for
//    both source rows AND the detail's `"DESTINATION"` slot.
//  • `.overlayPreferenceValue(AnchorKey.self) { ... }` — the single
//    overlay reads both anchors and renders the morphing image.
//  • `withAnimation(.snappy(0.35), completionCriteria: .logicallyComplete) { ... } completion: { ... }`
//    — two-phase animation. Drives `heroProgress`, then on
//    completion hides the hero overlay so taps go to the real view.
//  • `@AppStorage("toggleDarkMode") / ("activeDarkMode")` — the
//    user-facing toggle persists; `activeDarkMode` flips AFTER the
//    mask animation completes, so the snapshot transition isn't
//    spoiled by an early color-scheme change.
//  • `.preferredColorScheme(activeDarkMode ? .dark : .light)`
//  • `.mask(alignment: .topLeading) { Circle().frame(... maskAnimation ? 80 : 1).offset(...) }`
//    — the circular reveal; multiplying `width * 80` is the trick
//    that grows the mask off-screen to fully expose the new snapshot.
//  • `Slider(value: $heroProgress)` — debugging affordance, leave it
//    in for inspection or strip it for production.
//
//  How to apply
//  ────────────
//  Reach for technique #1 when you want SCRUBBABLE hero animation
//  (drag to dismiss with live preview). Reach for #3 when you want
//  the dark-mode snapshot transition; it pairs naturally with any
//  `@AppStorage`-backed binary toggle, not just dark mode.
//
//  See also
//  ────────
//  • BasicProfileAnimationView.swift — the simpler version of the
//    anchor-preference hero (no `heroProgress`, no swipe-to-dismiss).
//  • ListExpandSheetHeroAnimationView.swift — when the morph needs
//    to cross a sheet/push boundary, use that file's `HeroWrapper`.
//

import SwiftUI

struct ProfileListView: View {
    /// View properties - profiles
    @State private var allProfiles: [Profile] = profiles
    @State private var selectedProfile: Profile?
    @State private var showDetail: Bool = false
    @State private var heroProgress: CGFloat = 0
    @State private var showHeroView: Bool = true

    /// View properties - dark mode animation

    @AppStorage("toggleDarkMode") private var toggleDarkMode: Bool = false
    // persisted with app storage
    @AppStorage("activeDarkMode") private var activeDarkMode: Bool = false
    @State private var buttonRect: CGRect = .zero
    /// current & previous state snapshot images
    @State private var currentImage: UIImage?
    @State private var previousImage: UIImage?
    @State private var maskAnimation: Bool = false

    var body: some View {
        NavigationStack {
            CustomTextFieldKeyboardsDemoView()

            List(allProfiles) { profile in
                HStack {
                    Image(profile.profilePicture)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .clipShape(.circle)
                        .opacity(selectedProfile?.id == profile.id ? 0 : 1)
                        .anchorPreference(key: AnchorKey.self,
                                          value: .bounds,
                                          transform: { anchor in
                                              [profile.id.uuidString: anchor]
                                          })

                    VStack(alignment: .leading, spacing: 6) {
                        Text(profile.username)
                            .fontWeight(.semibold)

                        Text(profile.lastMsg)
                            .font(.caption2)
                            .foregroundStyle(.gray)
                    }
                }
                .contentShape(.rect)
                .onTapGesture {
                    selectedProfile = profile
                    showDetail = true

                    withAnimation(.snappy(duration: 0.35, extraBounce: 0),
                                  completionCriteria: .logicallyComplete)
                    {
                        heroProgress = 1.0
                    } completion: {
                        Task {
                            /// adding delay for the hero view overlay
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
        .overlayPreferenceValue(AnchorKey.self) { value in
            GeometryReader { geometry in
                if let selectedProfile,
                   let source = value[selectedProfile.id.uuidString],
                   let destination = value["DESTINATION"]
                {
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

                    // swiftlint:disable:next todo
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
        }
        /// some visual help
        .overlay(alignment: .bottom) {
            Slider(value: $heroProgress)
                .padding()
        }
        .createImages(
            toggleDarkMode: toggleDarkMode,
            currentImage: $currentImage,
            previousImage: $previousImage,
            activeDarkMode: $activeDarkMode
        )
        .overlay(content: {
            GeometryReader(content: { geometry in
                let size = geometry.size
                if let previousImage, let currentImage {
                    ZStack {
                        Image(uiImage: previousImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size.width, height: size.height)

                        Image(uiImage: currentImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size.width, height: size.height)
                            .mask(alignment: .topLeading) {
                                Circle() /// the start point of transition animation
                                    .frame(width: buttonRect.width * (maskAnimation ? 80 : 1),
                                           height: buttonRect.height * (maskAnimation ? 80 : 1),
                                           alignment: .bottomLeading)
                                    .frame(width: buttonRect.width, height: buttonRect.height)
                                    .offset(x: buttonRect.midX, y: buttonRect.minY)
                                    .ignoresSafeArea()
                            }
                    }
                    .offset(y: 42) // tab bar height - safe area bottom
                    .task {
                        guard !maskAnimation else { return }
                        withAnimation(.easeInOut(duration: 0.9), completionCriteria: .logicallyComplete) {
                            maskAnimation = true
                        } completion: {
                            /// Removing all snapshots
                            self.currentImage = nil
                            self.previousImage = nil
                            maskAnimation = false
                        }
                    }
                }
            })
            /// Reverse masking
            .mask {
                Rectangle()
                    .overlay(alignment: .topLeading) {
                        Circle() /// the start point of transition animation
                            .frame(width: buttonRect.width, height: buttonRect.height)
                            .offset(x: buttonRect.midX, y: buttonRect.minY)
                            .blendMode(.destinationOut)
                    }
            }
            .ignoresSafeArea()
        })
        .overlay(alignment: .topTrailing) {
            Button(action: {
                toggleDarkMode.toggle()
            }, label: {
                Image(systemName: toggleDarkMode ? "sun.max.fill" : "moon.fill")
                    .font(.title2)
                    .foregroundColor(.primary)
                    .symbolEffect(.bounce, value: toggleDarkMode)
                    .frame(width: 40, height: 40)
            })
            .darkModeRect { rect in
                buttonRect = rect
            }
            .padding(10)
            .disabled(currentImage != nil || previousImage != nil || maskAnimation)
        }
        .preferredColorScheme(activeDarkMode ? .dark : .light)
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
    @State private var offset: CGFloat = .zero
    @State private var star: Bool = true

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
                        .anchorPreference(key: AnchorKey.self,
                                          value: .bounds,
                                          transform: { anchor in
                                              ["DESTINATION": anchor]
                                          })
                        .visualEffect { content, geometryProxy in
                            content // add drag down offset
                                .offset(y: geometryProxy.frame(in: .scrollView).minY > 0
                                    ? -geometryProxy.frame(in: .scrollView).minY : 0)
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
                    VStack {
                        Button(action: {
                            showHeroView = true
                            withAnimation(.snappy(duration: 0.35, extraBounce: 0),
                                          completionCriteria: .logicallyComplete)
                            {
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
                }
                .offset(x: size.width - (size.width * heroProgress))
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(.clear)
                        .frame(width: 10)
                        .contentShape(.rect)
                        .gesture(
                            DragGesture()
                                .updating($isDragging, body: { _, out, _ in
                                    out = true
                                })
                                .onChanged { value in
                                    /// enable hero layer view when gesture start to dismiss the view
                                    var translation = value.translation.width
                                    translation = isDragging ? translation : .zero
                                    translation = translation > 0 ? translation : 0
                                    offset = translation

                                    /// Convering into progress
                                    let dragProgress = 1.0 - (translation / size.width)
                                    /// Limiting progress between (1,0)
                                    let cappedProgress = min(max(0, dragProgress), 1)
                                    heroProgress = cappedProgress
                                    if !showHeroView {
                                        showHeroView = true
                                    }
                                }
                                .onEnded { value in
                                    /// Closing/Resetting based on end target
                                    let velocity = value.velocity.width

                                    if (offset + velocity) > (size.width * 0.8) {
                                        /// Close view
                                        withAnimation(.snappy(duration: 0.35, extraBounce: 0),
                                                      completionCriteria: .logicallyComplete)
                                        {
                                            heroProgress = .zero
                                        } completion: {
                                            offset = .zero
                                            showDetail = false
                                            showHeroView = true
                                            self.selectedProfile = nil
                                        }
                                    } else {
                                        /// Reset
                                        withAnimation(.snappy(duration: 0.35, extraBounce: 0),

                                                      completionCriteria: .logicallyComplete)
                                        {
                                            heroProgress = 1.0
                                            offset = .zero
                                        } completion: {
                                            showHeroView = false
                                        }
                                    }
                                }
                        )
                }
            }
        }
    }
}

#Preview {
    ProfileListView()
}
