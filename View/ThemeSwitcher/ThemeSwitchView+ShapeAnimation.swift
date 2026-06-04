//
//  ThemeSwitchView.swift
//  animation
//
//  Learning point
//  ──────────────
//  Polished theme picker sheet — a giant gradient circle, a
//  "Choose a Style" headline, and a 3-segment picker
//  (Default / Light / Dark) with a sliding selection capsule.
//  When the system colour scheme flips, the circle MORPHS via
//  an inverted-mask trick to show the active scheme's accent
//  colour from a different anchor (bottom-right in dark mode,
//  off-screen in light mode).
//
//  Three reusable mechanics
//  ────────────────────────
//    1. **Inverted-mask circle reveal** — a `Circle` filled with
//       the active accent colour is masked by a `Rectangle`
//       overlaid with another `Circle` blended in
//       `.destinationOut`. The blend ERASES the overlay's circle
//       from the rectangle, leaving a circular hole. As
//       `circleOffset` animates between (30, -25) and (150, -150),
//       the hole moves — making the visible "moon"-shaped sliver
//       of the gradient circle slide accordingly. Perfect for
//       Apple-Watch-faces-style reveal effects.
//    2. **`matchedGeometryEffect` for segmented selection** —
//       the picked Theme's capsule background uses
//       `matchedGeometryEffect(id: "ACTIVETAB", in: animation)`,
//       so SwiftUI animates ONE capsule between segments rather
//       than fading two capsules at the new + old positions.
//    3. **`@AppStorage` for theme persistence + `.preferredColorScheme`** —
//       `userTheme` (Default / Light / Dark) maps to a
//       `ColorScheme?` (nil = system). Applying
//       `.preferredColorScheme(userTheme.colorScheme)` at the
//       root means the choice survives launches and applies
//       app-wide.
//
//  Why pass `scheme` as init parameter (not `@Environment`)
//  ────────────────────────────────────────────────────────
//  See the comment on line 30:
//
//      // @Environment(\.colorScheme) didn't work in sheet
//
//  iOS sheets are presented in their own UIWindow with their own
//  trait collection. Reading `@Environment(\.colorScheme)` inside
//  the sheet doesn't always reflect the parent's scheme. The
//  workaround is to pass the resolved scheme in via init from
//  the parent view (which CAN read the environment correctly).
//
//  Why animate `circleOffset` from `onChange(of: scheme)`
//  ──────────────────────────────────────────────────────
//  When the user picks a new theme, the system scheme can change
//  (e.g. Light → Dark). We catch this via
//  `onChange(of: scheme)` and animate the mask circle to its new
//  position with `.bouncy` for a playful elastic landing.
//
//  Why `.presentationBackground(.clear)`
//  ─────────────────────────────────────
//  We want the sheet to FLOAT — the background of `ThemeSwitchView`
//  itself paints the rounded rectangle. `.presentationBackground(.clear)`
//  removes the system sheet's default background fill so our
//  inner `clipShape(.rect(cornerRadius: 30))` is what the user
//  sees. Combined with `.height(410)` detent, this gives the
//  iOS-Music-style floating appearance.
//
//  Key APIs
//  ────────
//  • `@AppStorage` (with custom enum) — persistent enum storage.
//  • `.preferredColorScheme(_:)` — pin app-wide scheme; `nil`
//    means follow system.
//  • `matchedGeometryEffect(id:in:)` + `@Namespace` — segment
//    capsule sliding.
//  • `.blendMode(.destinationOut)` — punch a hole in the parent.
//  • `.presentationBackground(.clear)` + `.presentationDetents([.height(...)])`
//    — floating sheet recipe.
//  • `.environment(\.colorScheme, scheme)` — force a colorScheme
//    on a subtree (workaround for sheet environment isolation).
//
//  How to apply
//  ────────────
//  Use this entire file as a template for any "picker sheet that
//  reflects current selection" — sound modes, brightness presets,
//  font picks. The inverted-mask reveal is the visual signature
//  worth keeping.
//
//  See also
//  ────────
//  • ThemeSwitcherView.swift — sister minimal demo using
//    `@AppStorage` + `SchemeHostView`.
//
import SwiftUI

struct ThemeSwitchDemoView: View {
    @Environment(\.colorScheme) private var scheme
    @State private var changeTheme: Bool = false
    @AppStorage("user_theme") private var userTheme: Theme = .systemDefault

    var body: some View {
        NavigationStack {
            List {
                Section("Appearance") {
                    Button("Change Theme") {
                        changeTheme.toggle()
                    }
                }
            }
            .navigationTitle("Settings")
        }
        .preferredColorScheme(userTheme.colorScheme)
        .sheet(isPresented: $changeTheme, content: {
            ThemeSwitchView(scheme: scheme)
                .presentationDetents([.height(410)]) /// maxHeight is 410
                .presentationBackground(.clear)
        })
    }
}

struct ThemeSwitchView: View {
    // @Environment(\.colorScheme) private var scheme // didn't work in sheet
    var scheme: ColorScheme
    @AppStorage("user_theme") private var userTheme: Theme = .systemDefault
    /// Sliding effect
    @Namespace private var animation
    /// View Properties
    @State private var circleOffset: CGSize = .zero
    init(
        scheme: ColorScheme
    ) {
        self.scheme = scheme
        let isDark = scheme == .dark
        _circleOffset = .init(
            initialValue: CGSize(width: isDark ? 30 : 150,
                                 height: isDark ? -25 : -150)
        )
    }

    var body: some View {
        VStack(spacing: 15) {
            // Tip: the inverted-mask "moon" reveal.
            // We start with a full gradient Circle. Then mask it with:
            //   Rectangle (opaque everywhere)
            //     .overlay { Circle().offset(...).blendMode(.destinationOut) }
            // The overlaid Circle ERASES itself from the Rectangle
            // (`.destinationOut`), leaving the rectangle with a circular
            // HOLE. Using that as a mask, only the part of the gradient
            // outside the hole is visible — producing the crescent / moon
            // sliver. Animating `circleOffset` shifts the hole, sweeping
            // the visible sliver around.
            Circle()
                .fill(userTheme.color(scheme).gradient)
                .frame(width: 150, height: 150)
                .mask {
                    Rectangle()
                        .overlay {
                            Circle()
                                .offset(circleOffset)
                                .blendMode(.destinationOut)
                        }
                }

            Text("Choose a Style")
                .font(.title2.bold())
                .padding(.top, 25)
//                .foregroundStyle(userTheme.color(scheme))

            Text("Pop or subtle. Day or night.\nCustomize your interface.")
                .multilineTextAlignment(.center)
//                .foregroundStyle(userTheme.color(scheme))

            /// Segment picker
            HStack(spacing: 0) {
                ForEach(Theme.allCases, id: \.rawValue) { theme in
                    Text(theme.rawValue)
                        .padding(.vertical, 15)
                        .frame(width: 100)
                        // Tip: same-id matchedGeometryEffect across the
                        // ForEach makes ONE capsule appear to slide
                        // between the active segment positions instead
                        // of fading in/out at the new index.
                        .background {
                            ZStack {
                                if userTheme == theme {
                                    Capsule()
                                        .fill(theme.backgroundColor(scheme))
                                        .matchedGeometryEffect(id: "ACTIVETAB", in: animation)
                                }
                            }
                            .animation(.snappy, value: userTheme)
                        }
                        .contentShape(.rect)
                        .onTapGesture {
                            userTheme = theme
                        }
                }
            }
            .padding(3)
            .background(.primary.opacity(0.06), in: .capsule)
            .padding(.top, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(height: 410) /// maxHeight
        .background(userTheme.backgroundColor(scheme))
        .clipShape(.rect(cornerRadius: 30))
        .padding(.horizontal, 15)
        .environment(\.colorScheme, scheme)
        .onChange(of: scheme, initial: false) { _, newValue in
            let isDark = newValue == .dark
            withAnimation(.bouncy) {
                circleOffset = CGSize(width: isDark ? 30 : 150,
                                      height: isDark ? -25 : -150)
            }
        }
    }
}

#Preview {
    ThemeSwitchDemoView()
}

enum Theme: String, CaseIterable {
    case systemDefault = "Default"
    case light = "Light"
    case dark = "Dark"

    func color(_ scheme: ColorScheme) -> Color {
        switch self {
        case .systemDefault:
            scheme == .dark ? .purple : .orange
        case .light:
            .orange
        case .dark:
            .purple
        }
    }

    func backgroundColor(_ scheme: ColorScheme) -> Color {
        switch self {
        case .systemDefault:
            scheme == .dark ? .gray.opacity(0.7) : .gray.opacity(0.1)
        case .light:
            .white
        case .dark:
            .brown
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .systemDefault:
            nil
        case .light:
            .light
        case .dark:
            .dark
        }
    }
}
