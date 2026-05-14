//
//  View+Compat.swift
//  animation
//
// Purpose: version-gated SwiftUI compatibility shims.
//
// What belongs here:
//   - Anything wrapped in `if #available(iOS N, *)` that falls back to an
//     older API or a no-op on earlier OS versions.
//   - Small backports that let call sites write one call that works on all
//     supported iOS versions.
//
// What does NOT belong here:
//   - Helpers that don't branch on OS version (put those next to the concern:
//     View+Geometry, View+Visibility, View+Animation, etc.).
//   - Feature-specific demo helpers (colocate with the demo view).
//
// Naming convention: `try...` / `optional...` / `backported...` for shims,
// so readers can tell at a glance that the behavior degrades on older OS.
//

import SwiftUI

public extension View {
    /// `true` on iOS 26 and later. Use to gate entire UI branches when a
    /// modifier is insufficient.
    var isiOS26OrLater: Bool {
        if #available(iOS 26, *) {
            true
        } else {
            false
        }
    }

    /// Applies `.glassEffect()` on iOS 26+, no-op on earlier versions.
    @ViewBuilder
    func tryGlassEffect() -> some View {
        if #available(iOS 26.0, tvOS 26.0, *) {
            self.glassEffect()
        } else {
            self
        }
    }

    /// Applies `.glassEffect(in:)` with a custom shape on iOS 26+, no-op otherwise.
    @ViewBuilder
    func tryGlassEffect(in shape: some Shape) -> some View {
        if #available(iOS 26.0, tvOS 26.0, *) {
            self.glassEffect(in: shape)
        } else { self }
    }

    /// Tinted, interactive glass on iOS 26+. On older versions falls back to
    /// a solid rounded-rectangle background matching the color scheme.
    @ViewBuilder
    func optionalGlassEffect(_ colorScheme: ColorScheme, cornerRadius: CGFloat = 30) -> some View {
        let backgroundColor = colorScheme == .dark ? Color.black : Color.white
        if #available(iOS 26.0, *) {
            self.glassEffect(
                .clear.tint(backgroundColor.opacity(0.75)).interactive(),
                in: .rect(cornerRadius: cornerRadius, style: .continuous)
            )
        } else {
            background {
                RoundedRectangle(
                    cornerRadius: cornerRadius,
                    style: .continuous
                )
                .fill(backgroundColor)
            }
        }
    }

    /// Unified `onChange` across the iOS 17 signature change.
    /// iOS 17+: `(oldValue, newValue)`. Pre-17: `(newValue)`.
    /// `@ViewBuilder` reconciles the two branches' different return types.
    @ViewBuilder
    func customOnChange<T: Equatable>(value: T, perform: @escaping (T) -> Void) -> some View {
        if #available(iOS 17, *) {
            self
                .onChange(of: value) { _, newValue in
                    perform(newValue)
                }
        } else {
            onChange(of: value) { newValue in
                perform(newValue)
            }
        }
    }

    @ViewBuilder
    func optionalGlassButtonStyle() -> some View {
        if #available(iOS 26, *) {
            self
                .buttonStyle(.glassProminent)
        } else {
            buttonStyle(.borderedProminent)
        }
    }
}
