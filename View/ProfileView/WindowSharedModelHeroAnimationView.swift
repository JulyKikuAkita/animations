//
//  WindowSharedModelHeroAnimationView.swift
//  animation
//
//  Learning point
//  ──────────────
//  This file is a RENDERER, not a standalone demo. `CustomHeroAnimationView`
//  is the View that gets installed as the root of the SECONDARY
//  hero-overlay UIWindow created by `SceneDelegate.addHeroWindow(_:)`
//  for `ProfileList+SheetView.swift`. It does ONE job: read
//  `WindowSharedModel` and draw the morphing avatar at
//  `sourceRect`, applying a corner-radius transition and an
//  optional bottom-fade gradient when `showGradient` flips.
//
//  Why the gradient overlay matters: when the avatar morphs from a
//  small circle row → a large rect at the top of a sheet, the bottom
//  edge has to BLEND INTO the sheet's background colour or the user
//  sees a visible cut. The gradient runs from `.clear` to
//  `colorScheme == .dark ? .black : .white`, matched to the host
//  sheet's surface.
//
//  Key APIs
//  ────────
//  • `@Environment(WindowSharedModel.self)` — read-only here; writes
//    happen in `ProfileList+SheetView.swift`.
//  • Implicit `.animation(.snappy(0.3), value: showGradient)` on the
//    overlay AND `.animation(.snappy(0.3), value: sourceRect)` on
//    the outer GeometryReader — together they animate frame and
//    gradient together.
//  • `.ignoresSafeArea()` — required because the hero window covers
//    the full screen including unsafe edges.
//
//  How to apply
//  ────────────
//  Don't reuse this file directly — it's tightly coupled to
//  `WindowSharedModel`. To build a similar overlay, copy the shape:
//  one shared model + one renderer view + a SceneDelegate that hosts
//  it in a passthrough window. Or just use
//  `ListExpandSheetHeroAnimationView.swift`'s `HeroWrapper` API,
//  which encapsulates this whole pattern.
//
//  See also
//  ────────
//  • ProfileList+SheetView.swift — the demo that USES this renderer.
//    Read the two files together; neither makes sense alone.
//

import SwiftUI

struct CustomHeroAnimationView: View {
    /// Color Scheme
    @Environment(\.colorScheme) private var scheme
    @Environment(WindowSharedModel.self) private var windowShareModel
    var body: some View {
        GeometryReader(content: { _ in
            VStack {
                let sourceRect = windowShareModel.sourceRect
                if let selectedProfile = windowShareModel.selectedProfile, windowShareModel.hideNativeView {
                    Image(selectedProfile.profilePicture)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: sourceRect.width, height: sourceRect.height)
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
                                .opacity(windowShareModel.showGradient ? 1 : 0)
                        }
                        .clipShape(.rect(cornerRadius: windowShareModel.cornerRadius))
                        .offset(x: sourceRect.minX, y: sourceRect.minY)
                        .animation(.snappy(duration: 0.3, extraBounce: 0), value: windowShareModel.showGradient)
                }
            }
            /// animating frame changes
            .animation(.snappy(duration: 0.3, extraBounce: 0), value: windowShareModel.sourceRect)
            .ignoresSafeArea()
        })
    }
}
