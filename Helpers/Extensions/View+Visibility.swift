//
//  View+Visibility.swift
//  animation
//
// Purpose: show/hide/fade helpers that produce a visible visual effect.
//
// What belongs here:
//   - Small conditional show/hide modifiers (`hideWit...`) that combine
//     opacity + offset/scale so callers can write one call instead of two.
//   - Presentational blur/opacity transitions (`blurFade...`).
//   - Toolbar/tab-bar visibility shortcuts.
//
// What does NOT belong here:
//   - Layout geometry (View+Geometry.swift).
//   - Transaction-based animation toggles (View+Animation.swift).
//   - Version-gated effects — if a helper branches on `#available`, it goes
//     in View+Compat.swift.
//
// Convention: modifiers take a plain `Bool` (or no arg) and return `some View`.
// Keep them parameter-light; a helper with >2 knobs probably deserves its own
// ViewModifier instead.
//

import SwiftUI

extension View {
    /// Fades the view in/out with a subtle vertical shift.
    /// `true` → visible, `false` → hidden and slightly offset.
    @ViewBuilder
    func hideWitOffset(_ isHidden: Bool) -> some View {
        offset(y: isHidden ? 10 : 0)
            .opacity(isHidden ? 0 : 1)
    }

    /// Fades the view in/out with a scale shrink.
    @ViewBuilder
    func hideWitScale(_ isHidden: Bool) -> some View {
        scaleEffect(isHidden ? 0.5 : 1)
            .opacity(isHidden ? 0 : 1)
    }

    /// Hides the tab bar from a view hierarchy (e.g. when presenting a sheet
    /// over a TabView — Apple Maps bottom-sheet pattern).
    @ViewBuilder
    func hideNaviTabBar() -> some View {
        toolbar(.hidden, for: .tabBar)
    }

    /// Blur + fade on a single view. Pair with `withAnimation` at the call site.
    func blurFade(_ status: Bool) -> some View {
        blur(radius: status ? 0 : 5)
            .opacity(status ? 1 : 0)
    }

    /// Same as `blurFade` but with `compositingGroup()` so the blur applies
    /// to the composed layer — use when multiple sibling views must fade
    /// together as a single unit.
    func blurFadeViews(_ status: Bool) -> some View {
        compositingGroup()
            .blur(radius: status ? 0 : 10)
            .opacity(status ? 1 : 0)
    }
}
