//
//  ProfileList+SheetView.swift
//  animation
//
//  Learning point
//  ──────────────
//  Hero animation across a SHEET BOUNDARY using a SECOND UIWINDOW set
//  up by `SceneDelegate` (`sceneDelegate.addHeroWindow(_:)`). The
//  reason to split into two windows: a `.sheet` is presented on the
//  main window, but the hero LAYER must float above BOTH the sheet
//  and the underlying list — that means it can't live in either's
//  view tree. So we add a hero-only `UIWindow` and let it host
//  `CustomHeroAnimationView` (defined in
//  `WindowSharedModelHeroAnimationView.swift`) which reads from a
//  shared `WindowSharedModel`.
//
//  The interaction sequence (open):
//    1. Tap a row → record its `geometry.frame(in: .global)` as
//       `windowSharedModel.sourceRect`, set `selectedProfile`,
//       `cornerRadius`, and `previousSourceRect` (saved for the close
//       animation).
//    2. `hideNativeView = true` → row + sheet image both go invisible;
//       the hero window's view becomes the only thing rendering the
//       avatar.
//    3. `showProfileView.toggle()` presents the sheet.
//    4. The sheet's `DetailedSheetProfileView` publishes ITS OWN
//       global frame via `RectKey`; on `.onPreferenceChange` we feed
//       it back into `sourceRect` so the hero view animates to fill
//       the sheet's image area.
//
//  Close inverts the sequence using `previousSourceRect`.
//
//  Why preview is unavailable
//  ──────────────────────────
//  `@Environment(SceneDelegate.self)` is unsatisfied in `#Preview`
//  because previews don't construct the real UIApplicationDelegate
//  graph. Run on the simulator to test.
//
//  Key APIs
//  ────────
//  • `@Environment(WindowSharedModel.self)` + `@Environment(SceneDelegate.self)`
//    — observable state shared across both windows.
//  • Custom `RectKey: PreferenceKey` — a tiny one-CGRect preference
//    used by the sheet to publish its destination frame to the
//    enclosing view (which then writes it onto `WindowSharedModel`).
//  • `interactiveDismissDisabled()` + `presentationDragIndicator(.hidden)`
//    — required so the sheet can't be dismissed mid-animation.
//  • `Task { ... try? await Task.sleep(...) ... }` chains — used as
//    a quick way to sequence frame writes within the same animation
//    tick.
//
//  How to apply
//  ────────────
//  Use this when you must hero-animate across a sheet boundary AND
//  you can own the SceneDelegate. For new code, prefer
//  `ListExpandSheetHeroAnimationView.swift`'s `HeroWrapper` —  it
//  spins up the overlay window itself and keeps preview-friendly.
//
//  See also
//  ────────
//  • WindowSharedModelHeroAnimationView.swift — the View that
//    actually renders inside the hero window for THIS demo. Pair.
//  • ListExpandSheetHeroAnimationView.swift — the modern reusable
//    rewrite with the same goal.
//

import SwiftUI

struct ProfileListSheetView: View {
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
    @Environment(WindowSharedModel.self) private var windowSharedModel
    @Environment(SceneDelegate.self) private var sceneDelegate
    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 15) {
                ForEach(profiles) { profile in
                    HStack(spacing: 12) {
                        /// to find view's position
                        GeometryReader(content: { geometry in
                            let rect = geometry.frame(in: .global)

                            Image(profile.profilePicture)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: rect.width, height: rect.height)
                                .clipShape(.circle)
                                .contentShape(.circle)
                                .opacity(
                                    windowSharedModel.selectedProfile?.id == profile.id ?
                                        (windowSharedModel.hideNativeView || showProfileView ? 1 : 0)
                                        : 1
                                )
                                .onTapGesture {
                                    Task {
                                        /// Opening profile
                                        selectedProfile = profile
                                        windowSharedModel.selectedProfile = profile
                                        windowSharedModel.cornerRadius = rect.width / 2
                                        windowSharedModel.sourceRect = rect
                                        /// Storing the source rect for closing animation
                                        windowSharedModel.previousSourceRect = rect
                                        try? await Task.sleep(for: .seconds(0))
                                        windowSharedModel.hideNativeView = true
                                        showProfileView.toggle()

                                        /// After animation finished, removing hero view
                                        try? await Task.sleep(for: .seconds(0))
                                        if windowSharedModel.hideNativeView {
                                            windowSharedModel.hideNativeView = false
                                        }
                                    }
                                }
                        })
                        .frame(width: 50, height: 50)

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
            .presentationDragIndicator(.hidden)
        })
        /// Adding hero overlay window for performing hero animation
        .onAppear(perform: {
            guard sceneDelegate.heroWindow == nil else { return }
            sceneDelegate.addHeroWindow(windowSharedModel)
        })
    }
}

/// Detail profile view
struct DetailedSheetProfileView: View {
    @Binding var selectedProfile: Profile?
    @Binding var showProfileView: Bool
    /// Color Scheme
    @Environment(\.colorScheme) private var scheme
    @Environment(WindowSharedModel.self) private var windowSharedModel

    var body: some View {
        VStack {
            GeometryReader(content: { geometry in
                let size = geometry.size
                let rect = geometry.frame(in: .global)

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
                                color,
                            ], startPoint: .top, endPoint: .bottom)
                        }
                        .clipped()
                        .opacity(windowSharedModel.hideNativeView ? 0 : 1)
                        .preference(key: RectKey.self, value: rect)
                        .onPreferenceChange(RectKey.self, perform: { value in
                            if showProfileView {
                                windowSharedModel.sourceRect = value
                                /// showing Gradient
                                windowSharedModel.showGradient = true
                            }
                        })
                }
            })
            .frame(maxHeight: 330)
            .overlay(alignment: .topLeading) {
                Button(action: {
                    /// Closing the same way as opening
                    Task {
                        windowSharedModel.hideNativeView = true
                        showProfileView = false
                        try? await Task.sleep(for: .seconds(0))
                        /// Using the store source frame to re-positiong to it's original place
                        windowSharedModel.sourceRect = windowSharedModel.previousSourceRect
                        windowSharedModel.showGradient = false
                        /// waiting for animation completion
                        try? await Task.sleep(for: .seconds(0.5))
                        if windowSharedModel.hideNativeView {
                            windowSharedModel.reset()
                            selectedProfile = nil
                        }
                    }
                    /// Closing Profile
                    showProfileView = false
                }, label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(.white)
                        .contentShape(.rect)
                        .padding(10)
                        .background(.black, in: .circle)
                })
                .padding([.leading, .top], 20)
                .scaleEffect(0.9)
                .opacity(windowSharedModel.hideNativeView ? 0 : 1)
                .animation(.snappy, value: windowSharedModel.hideNativeView)
            }

            Spacer()
        }
    }
}

/// Preference key to read view bounds
struct RectKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}
