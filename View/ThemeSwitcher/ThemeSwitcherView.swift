//
//  ThemeSwitcherView.swift
//  animation
//
//  Learning point
//  ──────────────
//  Minimal demo for an app-wide theme switcher. The actual scheme
//  flip lives in `SchemeHostView` (project helper) which reads the
//  `@AppStorage("AppScheme")` value and applies
//  `.preferredColorScheme(...)` at the root. This file just shows
//  a screen that participates: a chats list with a moon-icon
//  toolbar button that toggles a SCENE-scoped picker overlay.
//
//  Two reusable mechanics
//  ────────────────────────
//    1. **`@AppStorage` for cross-launch persistence** — the
//       chosen scheme survives app restarts because the chosen
//       value is written to `UserDefaults` automatically.
//       `AppScheme` is a project-local enum (`device`, `light`,
//       `dark`); the property wrapper handles enum round-tripping
//       via `RawRepresentable`.
//    2. **`@SceneStorage` for per-scene UI state** —
//       `showPickerView` is restored if the user backgrounds the
//       app and returns. `@State` would lose it; `@AppStorage`
//       would persist it across LAUNCHES (overkill). `@SceneStorage`
//       is the middle ground: scoped to the current scene's
//       lifetime + state restoration.
//
//  Why animate the SCREEN, not the picker
//  ──────────────────────────────────────
//      .animation(.easeInOut(duration: 0.25), value: appScheme)
//
//  Putting the animation modifier on the chats list (not on the
//  picker overlay) means when the SCHEME changes, the entire
//  chats UI cross-fades between dark/light versions of itself
//  rather than snapping. The picker overlay can have its own
//  separate animation timing.
//
//  Why a moon icon (not toggle)?
//  ─────────────────────────────
//  iOS / macOS convention. Sun for light, moon for dark, gear/
//  ellipsis for "system." Single tap reveals the picker rather
//  than cycling — more discoverable for users who don't know
//  there's a third option.
//
//  Key APIs
//  ────────
//  • `@AppStorage(_:)` — `UserDefaults`-backed property wrapper.
//  • `@SceneStorage(_:)` — scene-scoped state restoration.
//  • `SchemeHostView` (project helper) — applies
//    `.preferredColorScheme` at the root based on stored value.
//
//  How to apply
//  ────────────
//  Drop this pattern into any app needing user-controllable
//  appearance: settings screens, in-app theme pickers, debug
//  menus. Pair with `[[ThemeSwitchView+ShapeAnimation]]` for the
//  fancier "circle reveal" animation between schemes.
//
//  See also
//  ────────
//  • ThemeSwitchView+ShapeAnimation.swift — sister sheet-based
//    picker with an inverted-mask circle reveal.
//

import SwiftUI

struct ThemeSwitcherDemoView: View {
    @AppStorage("AppScheme") private var appScheme: AppScheme = .device
    @SceneStorage("ShowScenePickerView") private var showPickerView: Bool = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(1 ... 40, id: \.self) {
                    Text("Chat History \($0)")
                }
            }
            .navigationTitle("Chats")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showPickerView.toggle()
                    } label: {
                        Image(systemName: "moon.fill")
                            .foregroundStyle(Color.primary)
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: appScheme)
    }
}

#Preview {
    SchemeHostView {
        ThemeSwitcherDemoView()
    }
}
